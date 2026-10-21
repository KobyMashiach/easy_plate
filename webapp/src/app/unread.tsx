/* eslint-disable react-refresh/only-export-components */
// The inbox's unread count, live, for the bell and the menu badge: the same
// notifications/{uid}/items collection the app's inbox reads. One listener
// for the whole app (a provider), however many places show the count.
import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { useAuth } from "../lib/auth";
import { withFirestore } from "../lib/firebase";

const Ctx = createContext(0);

export function UnreadProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const [count, setCount] = useState(0);
  useEffect(() => {
    if (!user) {
      setCount(0);
      return;
    }
    return withFirestore(
      (fs, db) =>
        fs.onSnapshot(
          fs.query(fs.collection(db, "notifications", user.uid, "items"), fs.where("read", "==", false), fs.limit(100)),
          (snap) => setCount(snap.size),
          () => setCount(0),
        ),
      () => setCount(0),
    );
  }, [user]);
  return <Ctx.Provider value={count}>{children}</Ctx.Provider>;
}

export function useUnreadCount(): number {
  return useContext(Ctx);
}
