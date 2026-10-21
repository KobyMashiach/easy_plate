// Answering a share invite, whatever it is for — the inbox, the sharing page
// and a redeemed code all go through here, as the app's three screens all
// go through RespondToShareInviteUseCase / ContainerSharingService.
import { acceptRecipeInvite, declineInvite } from "./collabRecipes";
import { acceptContainerInvite } from "./containers";
import type { CollabKind, ShareInvite } from "./types";

export interface Accepted {
  kind: CollabKind;
  localId: string;
  title: string;
}

export async function acceptInvite(invite: ShareInvite, uid: string, lang: string): Promise<Accepted> {
  if (invite.kind === "recipe") {
    const local = await acceptRecipeInvite(invite, lang);
    return { kind: "recipe", localId: local.id, title: local.title };
  }
  if (invite.kind === "household") throw new Error("A household is joined by code, never by invite");
  const local = await acceptContainerInvite(invite, uid, lang);
  return { kind: invite.kind, localId: local.id, title: invite.recipeTitle };
}

export const respondDecline = declineInvite;

/** Where the joined copy is opened on the web (the app pushes the recipe or book, or lands on the tab). */
export function pathForAccepted(kind: CollabKind, localId: string | null): string {
  switch (kind) {
    case "recipe":
      return localId ? `/recipes/${encodeURIComponent(localId)}` : "/recipes";
    case "book":
      return localId ? `/library/${encodeURIComponent(localId)}` : "/library";
    case "mealPlan":
      return localId ? `/plans/${encodeURIComponent(localId)}` : "/plans";
    case "groceryList":
      return localId ? `/groceries/${encodeURIComponent(localId)}` : "/groceries";
    default:
      return "/household";
  }
}

/** The success line the app shows for each kind (t.sharing.accepted / acceptedBook / …). */
export function acceptedKey(kind: CollabKind): string {
  return kind === "book" ? "sharing.acceptedBook" : kind === "mealPlan" ? "sharing.acceptedPlan" : kind === "groceryList" ? "sharing.acceptedList" : "sharing.accepted";
}
