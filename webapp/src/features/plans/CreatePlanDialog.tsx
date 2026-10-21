// New plan: a name and a starting template (meal_planner_page.dart
// _CreatePlanForm). The template only seeds meals on every weekday; the meal
// names are written in the UI language, as the app writes them.
import { useId, useState, type FormEvent } from "react";
import { useIsPhone } from "../../components/useIsPhone";
import { BottomSheet } from "../../components/BottomSheet";
import { ClayButton, ClayCard } from "../../components/clay";
import { Notice } from "../../components/ui";
import { saveErrorKey } from "../library/shared/store";
import { useI18n } from "../../lib/i18n";
import { Icon } from "../../components/icons";
import { PromptDialog } from "../library/shared/components";

export type PlanTemplate = "free" | "threeMeals" | "sixMeals";

export function templateMealKeys(template: PlanTemplate): string[] {
  if (template === "threeMeals") return ["plans.breakfast", "plans.lunch", "plans.dinner"];
  if (template === "sixMeals") return ["plans.breakfast", "plans.morningSnack", "plans.lunch", "plans.afternoonSnack", "plans.dinner", "plans.eveningSnack"];
  return [];
}

const TEMPLATES: { id: PlanTemplate; label: string; hint: string; icon: string }[] = [
  { id: "free", label: "plans.templateFree", hint: "plans.templateFreeHint", icon: "settings" },
  { id: "threeMeals", label: "plans.templateThree", hint: "plans.templateThreeHint", icon: "cook" },
  { id: "sixMeals", label: "plans.templateSix", hint: "plans.templateSixHint", icon: "timer" },
];

/** _CreatePlanForm's template icons: tune / restaurant / local_cafe. */
const PHONE_ICON: Record<PlanTemplate, string> = { free: "tune", threeMeals: "restaurant", sixMeals: "local_cafe" };

export function CreatePlanDialog(props: { onClose: () => void; onCreate: (name: string, mealNames: string[]) => Promise<void> }) {
  const phone = useIsPhone();
  return phone ? <PhoneCreatePlan {...props} /> : <DesktopCreatePlan {...props} />;
}

/** The app's create sheet: the name, the template cards (active = primaryContainer + check), save. */
function PhoneCreatePlan({ onClose, onCreate }: { onClose: () => void; onCreate: (name: string, mealNames: string[]) => Promise<void> }) {
  const { t } = useI18n();
  const id = useId();
  const formId = useId();
  const [name, setName] = useState("");
  const [template, setTemplate] = useState<PlanTemplate>("threeMeals");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const can = name.trim() !== "" && !busy;
  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (!can) return;
    setBusy(true);
    setError(null);
    try {
      await onCreate(name.trim(), templateMealKeys(template).map((k) => t(k)));
      onClose();
    } catch (err) {
      setError(t(saveErrorKey(err)));
      setBusy(false);
    }
  };
  return (
    <BottomSheet
      open
      onClose={onClose}
      dismissible={!busy}
      title={t("plans.newPlan")}
      footer={
        <ClayButton type="submit" form={formId} expanded icon="check" busy={busy} disabled={!can}>
          {t("library.ui.save")}
        </ClayButton>
      }
    >
      <form id={formId} onSubmit={submit}>
        <label htmlFor={id} className="sr-only">
          {t("plans.planName")}
        </label>
        <input id={id} className="clay-input" placeholder={t("plans.planName")} value={name} onChange={(e) => setName(e.target.value)} maxLength={120} autoFocus />
        {name.trim() === "" ? <p className="mt-1 ps-4 text-label-sm text-on-surface-variant">{t("plans.nameRequired")}</p> : null}
        <p className="mt-6 text-label-md">{t("plans.template")}</p>
        <div className="mt-2 space-y-2" role="radiogroup" aria-label={t("plans.template")}>
          {TEMPLATES.map((tpl) => {
            const on = tpl.id === template;
            return (
              <ClayCard key={tpl.id} radius={24} active={on} onClick={() => setTemplate(tpl.id)} role="radio" aria-checked={on}>
                <span className="flex items-center gap-3">
                  <Icon name={PHONE_ICON[tpl.id]} size={24} className={on ? "text-on-primary-container" : "text-primary"} />
                  <span className="min-w-0 flex-1">
                    <span className={`block text-body-md ${on ? "text-on-primary-container" : "text-on-surface"}`}>{t(tpl.label)}</span>
                    <span className={`mt-1 block text-label-md ${on ? "text-primary-fixed" : "text-outline"}`}>{t(tpl.hint)}</span>
                  </span>
                  {on ? <Icon name="check_circle" size={24} className="text-on-primary-container" /> : null}
                </span>
              </ClayCard>
            );
          })}
        </div>
        {error ? (
          <div className="mt-3">
            <Notice kind="error">{error}</Notice>
          </div>
        ) : null}
      </form>
    </BottomSheet>
  );
}

function DesktopCreatePlan({ onClose, onCreate }: { onClose: () => void; onCreate: (name: string, mealNames: string[]) => Promise<void> }) {
  const { t } = useI18n();
  const [template, setTemplate] = useState<PlanTemplate>("threeMeals");
  return (
    <PromptDialog
      title={t("plans.newPlan")}
      label={t("plans.planName")}
      confirmLabel={t("plans.create")}
      requiredHint={t("plans.nameRequired")}
      onClose={onClose}
      onSubmit={(name) => onCreate(name, templateMealKeys(template).map((k) => t(k)))}
    >
      <fieldset className="space-y-2">
        <legend className="mb-2 text-label-md text-on-surface-variant">{t("plans.template")}</legend>
        {TEMPLATES.map((tpl) => {
          const on = tpl.id === template;
          return (
            <label
              key={tpl.id}
              className={`flex cursor-pointer items-center gap-3 rounded-md border p-3 transition-colors focus-within:ring-2 focus-within:ring-primary ${on ? "border-primary bg-primary-container text-on-primary-container" : "border-outline-variant bg-surface-low"}`}
            >
              <input type="radio" name="plan-template" className="sr-only" checked={on} onChange={() => setTemplate(tpl.id)} />
              <Icon name={tpl.icon} className={on ? "" : "text-primary"} />
              <span className="min-w-0 flex-1">
                <span className="block text-body-md font-bold">{t(tpl.label)}</span>
                <span className={`block text-label-sm ${on ? "opacity-85" : "text-on-surface-variant"}`}>{t(tpl.hint)}</span>
              </span>
              {on ? <Icon name="check" size={18} /> : null}
            </label>
          );
        })}
      </fieldset>
    </PromptDialog>
  );
}
