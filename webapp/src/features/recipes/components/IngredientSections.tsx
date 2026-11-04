// The app's ingredient section headings: a small primary label above each run
// of ingredients sharing a `section`; nothing at all for an undivided list.
import { Fragment, type ReactNode } from "react";
import { hasSections, ingredientGroups, type Ingredient } from "../../../models/recipe";

export function SectionHeading({ section, first = false, as: Tag = "li", className = "" }: { section: string; first?: boolean; as?: "li" | "div"; className?: string }) {
  return (
    <Tag role={Tag === "li" ? "presentation" : undefined} className={`${first ? "" : "pt-3"} pb-1 text-label-md font-bold text-primary ${className}`}>
      {section}
    </Tag>
  );
}

/** The list's rows with a heading before each section; `row` draws one line by its original index (and keys it). */
export function SectionedIngredients<T extends Ingredient>({ ingredients, row, as = "li" }: { ingredients: T[]; row: (ing: T, index: number) => ReactNode; as?: "li" | "div" }) {
  if (!hasSections(ingredients)) return <>{ingredients.map((ing, i) => row(ing, i))}</>;
  return (
    <>
      {ingredientGroups(ingredients).map((g, n) => (
        <Fragment key={`s${n}`}>
          {g.section ? <SectionHeading section={g.section} first={n === 0} as={as} /> : null}
          {g.items.map(({ ing, index }) => row(ing, index))}
        </Fragment>
      ))}
    </>
  );
}
