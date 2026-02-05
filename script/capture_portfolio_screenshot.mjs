#!/usr/bin/env node

import { chromium } from 'playwright';

async function main() {
  const [,, url, outputPath] = process.argv;

  if (!url || !outputPath) {
    console.error('Usage: capture_portfolio_screenshot.mjs <url> <outputPath>');
    process.exit(1);
  }

  const browser = await chromium.launch({
    headless: true,
    args: [
      '--disable-dev-shm-usage',
      '--single-process',
    ],
  });
  const page = await browser.newPage();

  try {
    const VIEWPORT = { width: 1280, height: 450 };
    const GOTO_TIMEOUT_MS = 30000;  // shorter timeout for problematic sites
    const POST_LOAD_DELAY_MS = 3000; // allow loaders/animations to finish

    await page.setViewportSize(VIEWPORT);

    // Use a more forgiving waitUntil to avoid getting stuck on SPAs and long-idle pages.
    await page.goto(url, { waitUntil: 'load', timeout: GOTO_TIMEOUT_MS });

    await page.waitForTimeout(POST_LOAD_DELAY_MS);

    await page.screenshot({ path: outputPath, fullPage: false });

    await browser.close();
    process.exit(0);
  } catch (error) {
    console.error('Error capturing screenshot:', error);
    try {
      await browser.close();
    } catch (_) {}
    process.exit(1);
  }
}

main();
