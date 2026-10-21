import { useI18n } from "../lib/i18n";
import { PTitle, PCard, PLinkButton } from "./phoneParts";

export function NotFoundPage() {
  const { t } = useI18n();
  return (
    <>
      <PTitle title={t("common.notFound")} lead={t("common.notFoundBody")} />
      <PCard>
        <PLinkButton to="/" variant="tonal">
          {t("common.toAccount")}
        </PLinkButton>
      </PCard>
    </>
  );
}
