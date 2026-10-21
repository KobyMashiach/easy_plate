import { lazy } from "react";
// Library: the shelf of recipe books and the open-book viewer (ff_books).
import type { FeatureRoute } from "../../app/routing";
import { FeatureGate } from "../../components/FeatureGate";

// Pages load on first visit (a chunk per page), not with the whole app.
const LibraryPage = lazy(() => import("./LibraryPage").then((m) => ({ default: m.LibraryPage })));
const BookViewerPage = lazy(() => import("./BookViewerPage").then((m) => ({ default: m.BookViewerPage })));

export const routes: FeatureRoute[] = [
  {
    path: "/library",
    element: (
      <FeatureGate flag="ff_books" page>
        <LibraryPage />
      </FeatureGate>
    ),
  },
  {
    path: "/library/:id",
    element: (
      <FeatureGate flag="ff_books" page>
        <BookViewerPage />
      </FeatureGate>
    ),
  },
];
