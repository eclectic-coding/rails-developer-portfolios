#!/usr/bin/env node

import { chromium } from 'playwright';
import fs from 'fs';

async function main() {
  const [,, url, outputPath] = process.argv;

  if (!url || !outputPath) {
    console.error('Usage: capture_portfolio_screenshot.mjs <url> <outputPath>');
    process.exit(1);
  }

  const browser = await chromium.launch();
  const page = await browser.newPage();

  try {
    await page.goto(url, { waitUntil: 'networkidle', timeout: 60000 });
    await page.setViewportSize({ width: 1280, height: 720 });
    await page.screenshot({ path: outputPath, fullPage: true });
    await browser.close();
    process.exit(0);
  } catch (error) {
    console.error('Error capturing screenshot:', error);
    await browser.close();
    process.exit(1);
  }
}

main();

