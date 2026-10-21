import { lazy } from "react";
// The price book: products and receipts, a receipt's details, and scanning a
// receipt (ff_price_book; the scan itself also behind ff_receipt_scan).
import type { FeatureRoute } from "../../app/routing";
import { FeatureGate } from "../../components/FeatureGate";

// Pages load on first visit (a chunk per page), not with the whole app.
const PriceBookPage = lazy(() => import("./PriceBookPage").then((m) => ({ default: m.PriceBookPage })));
const ReceiptDetailsPage = lazy(() => import("./ReceiptDetailsPage").then((m) => ({ default: m.ReceiptDetailsPage })));
const ScanReceiptPage = lazy(() => import("./ScanReceiptPage").then((m) => ({ default: m.ScanReceiptPage })));

export const routes: FeatureRoute[] = [
  { path: "/prices", element: <FeatureGate flag="ff_price_book" page><PriceBookPage /></FeatureGate> },
  { path: "/prices/scan", element: <FeatureGate flag="ff_price_book" page><ScanReceiptPage /></FeatureGate> },
  { path: "/prices/receipts/:id", element: <FeatureGate flag="ff_price_book" page><ReceiptDetailsPage /></FeatureGate> },
];
