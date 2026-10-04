import { readFileSync, writeFileSync } from 'node:fs';
const base = new URL('./', import.meta.url);
const source = readFileSync(new URL('Sources/AppleClientDesign.swift', base), 'utf8');
const css = source.match(/static let css = #"""([\s\S]*?)"""#/)[1];
const template = readFileSync(new URL('DesignPreviewTemplate.html', base), 'utf8');
writeFileSync(new URL('../outputs/LINUX-SB-Apple-Design-Preview.html', base), template.replace('/* APP_DESIGN_CSS */', css));
console.log('Exported preview using the App design stylesheet.');
