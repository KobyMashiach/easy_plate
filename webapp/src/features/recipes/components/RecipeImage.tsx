// A recipe's photo from Storage, or the app's plate placeholder.
import { useEffect, useState } from "react";
import { storageUrl } from "../../../lib/storage";
import { Icon } from "../../../components/icons";

export function useStorageUrl(path: string | null | undefined): string | null {
  const [url, setUrl] = useState<string | null>(null);
  useEffect(() => {
    let live = true;
    setUrl(null);
    if (!path) return;
    storageUrl(path)
      .then((u) => live && setUrl(u))
      .catch(() => live && setUrl(null));
    return () => {
      live = false;
    };
  }, [path]);
  return url;
}

export function RecipeImage({
  path,
  alt = "",
  className = "",
  iconSize = 40,
  eager = false,
  fallbackIcon = "cook",
  fallbackClassName = "bg-primary-fixed text-on-primary-fixed-variant",
}: {
  path: string | null;
  alt?: string;
  className?: string;
  iconSize?: number;
  eager?: boolean;
  /** The placeholder's icon and colours (phone: ClayImage's restaurant_menu in primary). */
  fallbackIcon?: string;
  fallbackClassName?: string;
}) {
  const url = useStorageUrl(path);
  const [failed, setFailed] = useState(false);
  useEffect(() => setFailed(false), [url]);
  if (url && !failed) {
    return <img src={url} alt={alt} loading={eager ? "eager" : "lazy"} decoding="async" onError={() => setFailed(true)} className={`object-cover ${className}`} />;
  }
  return (
    <span className={`grid place-items-center ${fallbackClassName} ${className}`} aria-hidden={alt ? undefined : "true"} role={alt ? "img" : undefined} aria-label={alt || undefined}>
      <Icon name={fallbackIcon} size={iconSize} />
    </span>
  );
}
