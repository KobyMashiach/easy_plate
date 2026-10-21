// The door to a Shefi conversation locked to one item (the app's scoped
// AssistantFab): drawn only when both ff_assistant and ff_assistant_scoped
// are open to this account.
import { Link } from "react-router-dom";
import { Icon } from "../../components/icons";
import { useAccess } from "../../lib/flags";
import { useI18n } from "../../lib/i18n";

const LABEL = { recipe: "assistant.askAboutRecipe", plan: "assistant.askAboutPlan", list: "assistant.askAboutList" } as const;

export function AskShefiLink({ kind, id, compact = false }: { kind: "recipe" | "plan" | "list"; id: string; compact?: boolean }) {
  const { t } = useI18n();
  const main = useAccess("ff_assistant");
  const scoped = useAccess("ff_assistant_scoped");
  if (main !== "enabled" || scoped !== "enabled") return null;
  const label = t(LABEL[kind]);
  return (
    <Link
      to={`/assistant?scope=${kind}&id=${encodeURIComponent(id)}`}
      aria-label={label}
      title={label}
      className="inline-flex min-h-[44px] items-center gap-1.5 rounded-full bg-primary-fixed px-4 text-label-md text-on-primary-fixed-variant shadow-control hover:brightness-95"
    >
      <Icon name="assistant" size={18} className="text-primary" />
      <span className={compact ? "hidden sm:inline" : ""}>{label}</span>
    </Link>
  );
}
