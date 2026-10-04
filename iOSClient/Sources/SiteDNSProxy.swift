import Foundation
import Network
import Darwin
import Security

enum SiteDNSError: LocalizedError {
    case unavailable
    case invalidResponse
    var errorDescription: String? { "指定的加密 DNS 暂时不可用，请稍后重试。" }
}

actor SiteDoHResolver {
    static let shared = SiteDoHResolver()
    static let servers = [
        "https://cloudflare-dns.com/dns-query",
        "https://us-kan-w-p-1.nashkan.net/dns-query",
        "https://us-nyc-w-p-1.nashkan.net/dns-query",
        "https://dns.neeb.it/dns-query",
        "https://dns.nick-slowinski.de/dns-query",
        "https://dns.telekom.de/dns-query",
        "https://dns.t53.de/dns-query",
        "https://dns.vaioswolke.xyz/dns-query"
    ]
    private var cache: [String:(Date,[String])] = [:]
    private var preferred = 0
    func resolve(_ host: String) async throws -> [String] {
        guard host == "linux.sb" || host.hasSuffix(".linux.sb") else { throw SiteDNSError.unavailable }
        if let value = cache[host], value.0 > Date() { return value.1 }
        let identifier = UInt16.random(in: 1...UInt16.max)
        let wire = Self.question(host, identifier: identifier)
        if let addresses = try? await Self.cloudflareQuery(wire, identifier: identifier), !addresses.isEmpty {
            cache[host] = (Date().addingTimeInterval(60), addresses)
            preferred = 0
            #if DEBUG
            print("LINUXSB_DOH resolved \(host) using Cloudflare 1.1.1.1 (direct IP)")
            fflush(stdout)
            #endif
            return addresses
        }
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 10
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        for attempt in 1..<Self.servers.count {
            let index = (preferred + attempt) % Self.servers.count
            do {
                var request = URLRequest(url: URL(string: Self.servers[index])!)
                request.httpMethod = "POST"
                request.httpBody = wire
                request.setValue("application/dns-message", forHTTPHeaderField: "Content-Type")
                request.setValue("application/dns-message", forHTTPHeaderField: "Accept")
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { continue }
                let addresses = try Self.addresses(data, identifier: identifier)
                guard !addresses.isEmpty else { continue }
                preferred = index
                cache[host] = (Date().addingTimeInterval(60), addresses)
                #if DEBUG
                print("LINUXSB_DOH resolved \(host) using \(Self.servers[index])")
                fflush(stdout)
                #endif
                return addresses
            } catch { continue }
        }
        throw SiteDNSError.unavailable
    }
    static func question(_ host: String, identifier: UInt16) -> Data {
        var bytes: [UInt8] = [UInt8(identifier >> 8), UInt8(identifier & 255), 1, 0, 0, 1, 0, 0, 0, 0, 0, 0]
        for label in host.split(separator: ".") { let text = Array(label.utf8); bytes.append(UInt8(text.count)); bytes += text }
        bytes += [0, 0, 1, 0, 1]
        return Data(bytes)
    }
    static func addresses(_ data: Data, identifier: UInt16) throws -> [String] {
        let bytes = Array(data)
        func number(_ offset: Int) throws -> Int { guard offset >= 0, offset+1 < bytes.count else { throw SiteDNSError.invalidResponse }; return Int(bytes[offset])*256+Int(bytes[offset+1]) }
        guard bytes.count >= 12, try number(0) == Int(identifier), bytes[2] & 128 != 0, bytes[3] & 15 == 0 else { throw SiteDNSError.invalidResponse }
        func skipName(_ position: inout Int) throws {
            for _ in 0..<128 {
                guard position < bytes.count else { throw SiteDNSError.invalidResponse }
                let count = Int(bytes[position]); position += 1
                if count == 0 { return }
                if count & 192 == 192 { guard position < bytes.count else { throw SiteDNSError.invalidResponse }; position += 1; return }
                guard count <= 63, position+count <= bytes.count else { throw SiteDNSError.invalidResponse }; position += count
            }
            throw SiteDNSError.invalidResponse
        }
        var position = 12
        for _ in 0..<(try number(4)) { try skipName(&position); position += 4; guard position <= bytes.count else { throw SiteDNSError.invalidResponse } }
        var result: [String] = []
        for _ in 0..<(try number(6)) {
            try skipName(&position)
            let type = try number(position), recordClass = try number(position+2), length = try number(position+8)
            position += 10
            guard position+length <= bytes.count else { throw SiteDNSError.invalidResponse }
            if type == 1 && recordClass == 1 && length == 4 { result.append(bytes[position..<position+4].map(String.init).joined(separator: ".")) }
            position += length
        }
        return Array(Set(result)).sorted()
    }

    /// Bootstraps Cloudflare DoH by its anycast IP so resolving the DoH hostname
    /// does not depend on the system resolver or the user's external proxy.
    static func cloudflareQuery(_ question: Data, identifier: UInt16) async throws -> [String] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String], Error>) in
            let tls = NWProtocolTLS.Options()
            sec_protocol_options_set_tls_server_name(tls.securityProtocolOptions, "cloudflare-dns.com")
            let connection = NWConnection(host: "1.1.1.1", port: 443, using: NWParameters(tls: tls, tcp: NWProtocolTCP.Options()))
            let queue = DispatchQueue(label: "sb.client.cloudflare-doh")
            var response = Data()
            var finished = false
            var ready = false
            var timeout: DispatchWorkItem?
            func end(_ result: Result<[String], Error>) {
                guard !finished else { return }
                finished = true
                timeout?.cancel()
                connection.cancel()
                continuation.resume(with: result)
            }
            func readResponse() {
                connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, complete, error in
                    if let data { response.append(data) }
                    if let packet = Self.cloudflareDNSBody(response, complete: complete) {
                        do { end(.success(try Self.addresses(packet, identifier: identifier))) }
                        catch { end(.failure(error)) }
                    } else if error != nil || complete || response.count > 65536 {
                        end(.failure(SiteDNSError.invalidResponse))
                    } else { readResponse() }
                }
            }
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready where !ready:
                    ready = true
                    var request = Data("POST /dns-query HTTP/1.1\r\nHost: cloudflare-dns.com\r\nAccept: application/dns-message\r\nContent-Type: application/dns-message\r\nConnection: close\r\nContent-Length: \(question.count)\r\n\r\n".utf8)
                    request.append(question)
                    connection.send(content: request, completion: .contentProcessed { error in
                        if let error { end(.failure(error)) } else { readResponse() }
                    })
                case .failed(let error): end(.failure(error))
                case .cancelled where !finished: end(.failure(SiteDNSError.unavailable))
                default: break
                }
            }
            timeout = DispatchWorkItem { end(.failure(SiteDNSError.unavailable)) }
            queue.asyncAfter(deadline: .now() + 8, execute: timeout!)
            connection.start(queue: queue)
        }
    }

    private static func cloudflareDNSBody(_ response: Data, complete: Bool) -> Data? {
        guard let boundary = response.range(of: Data([13, 10, 13, 10])) else { return nil }
        let header = String(decoding: response[..<boundary.lowerBound], as: UTF8.self).lowercased()
        guard header.components(separatedBy: "\r\n").first?.contains(" 200 ") == true else { return nil }
        var body = response.subdata(in: boundary.upperBound..<response.endIndex)
        if header.contains("transfer-encoding: chunked") {
            let bytes = Array(body)
            var offset = 0
            var decoded = Data()
            while offset < bytes.count {
                guard let lineEnd = bytes[offset...].indices.dropLast().first(where: { bytes[$0] == 13 && bytes[$0 + 1] == 10 }),
                      let length = Int(String(decoding: bytes[offset..<lineEnd], as: UTF8.self).split(separator: ";").first ?? "", radix: 16) else { return nil }
                offset = lineEnd + 2
                if length == 0 { return decoded.isEmpty ? nil : decoded }
                guard offset + length + 2 <= bytes.count else { return nil }
                decoded.append(contentsOf: bytes[offset..<offset + length])
                offset += length + 2
            }
            return nil
        } else if let field = header.components(separatedBy: "\r\n").first(where: { $0.hasPrefix("content-length:") }),
                  let length = Int(field.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""), body.count >= length {
            return body.prefix(length)
        }
        return complete && !body.isEmpty ? body : nil
    }
}

final class SiteDNSProxy {
    static let shared = SiteDNSProxy()
    private let queue = DispatchQueue(label: "sb.client.doh-proxy")
    private var listener: NWListener?
    private var port: NWEndpoint.Port?
    private var callbacks: [(Result<NWEndpoint.Port,Error>)->Void] = []
    private var sessions: [UUID:SiteTunnel] = [:]
    func start(_ completion: @escaping (Result<NWEndpoint.Port,Error>)->Void) {
        queue.async {
            if let port = self.port { DispatchQueue.main.async { completion(.success(port)) }; return }
            self.callbacks.append(completion)
            if self.listener != nil { return }
            do {
                let parameters = NWParameters.tcp
                parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
                let listener = try NWListener(using: parameters, on: .any)
                self.listener = listener
                listener.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        guard let port = listener.port else { return }; self.port = port
                        let callbacks = self.callbacks; self.callbacks.removeAll()
                        callbacks.forEach { callback in DispatchQueue.main.async { callback(.success(port)) } }
                    case .failed(let error):
                        self.listener = nil; self.port = nil
                        let callbacks = self.callbacks; self.callbacks.removeAll()
                        callbacks.forEach { callback in DispatchQueue.main.async { callback(.failure(error)) } }
                    default: break
                    }
                }
                listener.newConnectionHandler = { connection in
                    guard self.sessions.count < 48 else { connection.cancel(); return }
                    let id = UUID()
                    let tunnel = SiteTunnel(client: connection, queue: self.queue) { self.sessions.removeValue(forKey: id) }
                    self.sessions[id] = tunnel; tunnel.start()
                }
                listener.start(queue: self.queue)
            } catch {
                let callbacks = self.callbacks; self.callbacks.removeAll()
                callbacks.forEach { callback in DispatchQueue.main.async { callback(.failure(error)) } }
            }
        }
    }
}

private final class SiteTunnel {
    let client: NWConnection
    let queue: DispatchQueue
    let finished: ()->Void
    var upstream: NWConnection?
    var header = Data()
    var closed = false
    init(client: NWConnection, queue: DispatchQueue, finished: @escaping ()->Void) { self.client = client; self.queue = queue; self.finished = finished }
    func start() {
        client.stateUpdateHandler = { state in
            switch state {
            case .failed, .cancelled: self.close()
            default: break
            }
        }
        client.start(queue: queue)
        readHeader()
    }
    func readHeader() {
        client.receive(minimumIncompleteLength: 1, maximumLength: 16384) { data, _, complete, error in
            if let data { self.header.append(data) }
            guard error == nil, !complete, self.header.count <= 32768 else { self.close(); return }
            guard let boundary = self.header.range(of: Data([13,10,13,10])) else { self.readHeader(); return }
            let line = String(decoding: self.header[..<boundary.lowerBound], as: UTF8.self).components(separatedBy: "\r\n").first ?? ""
            let parts = line.split(separator: " ")
            guard parts.count >= 2, parts[0] == "CONNECT" else { self.reject(); return }
            let authority = parts[1].split(separator: ":")
            guard authority.count == 2, authority[1] == "443" else { self.reject(); return }
            let host = String(authority[0]).lowercased()
            guard host == "linux.sb" || host.hasSuffix(".linux.sb") else { self.reject(); return }
            let buffered = self.header.subdata(in: boundary.upperBound..<self.header.count)
            Task {
                do { let addresses = try await SiteDoHResolver.shared.resolve(host); self.queue.async { self.connect(addresses, index: 0, buffered: buffered) } }
                catch { self.queue.async { self.reject() } }
            }
        }
    }
    func connect(_ addresses: [String], index: Int, buffered: Data) {
        guard !closed, index < addresses.count else { reject(); return }
        let connection = NWConnection(host: NWEndpoint.Host(addresses[index]), port: 443, using: .tcp)
        upstream = connection
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                connection.stateUpdateHandler = nil
                self.client.send(content: Data("HTTP/1.1 200 Connection Established\r\n\r\n".utf8), completion: .contentProcessed { error in
                    guard error == nil else { self.close(); return }
                    if !buffered.isEmpty { connection.send(content: buffered, completion: .contentProcessed { error in if error != nil { self.close() } }) }
                    self.pipe(self.client, connection); self.pipe(connection, self.client)
                })
            case .failed:
                connection.cancel(); self.connect(addresses, index: index+1, buffered: buffered)
            default: break
            }
        }
        connection.start(queue: queue)
    }
    func pipe(_ source: NWConnection, _ target: NWConnection) {
        guard !closed else { return }
        source.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, complete, error in
            guard error == nil else { self.close(); return }
            if let data, !data.isEmpty { target.send(content: data, completion: .contentProcessed { error in if error != nil || complete { self.close() } else { self.pipe(source,target) } }) }
            else if complete { self.close() } else { self.pipe(source,target) }
        }
    }
    func reject() { guard !closed else { return }; client.send(content: Data("HTTP/1.1 502 Bad Gateway\r\nContent-Length: 0\r\n\r\n".utf8), completion: .contentProcessed { _ in self.close() }) }
    func close() { guard !closed else { return }; closed = true; client.cancel(); upstream?.cancel(); finished() }
}
