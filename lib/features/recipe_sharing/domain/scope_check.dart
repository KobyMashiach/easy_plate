import '../../../core/hive/user_scope.dart';

/// Whether [uid] is still the account whose boxes are open.
///
/// The shared-recipe refresh runs on sign-in and on every resume and takes
/// a while (two queries, a save per changed copy). A sign-out and a sign-in
/// to another account in that window moved the boxes under it: the saves
/// that followed wrote account A's shared recipes into account B's library,
/// each with A's role on the document. Every writer in that path asks this
/// before it writes, and stops when the answer is no.
typedef ScopeCheck = bool Function(String uid);

/// The real answer: the scope's uid. Null — the sign-out wipe is under way,
/// or nobody is signed in — is a no as well.
bool scopedTo(String uid) => UserScope().uid == uid;
