(in-package :teatree)

;;; --- Link ---

(defvar *find-link-by-id*
  (sprintf "select ~a from links where id = ?;" (link-fields)))

(defvar *find-all-links-by-profile-id*
  (sprintf "select ~a from links where profile_id = ?;" (link-fields)))

(defvar *find-all-links-by-username*
  (sprintf "select ~a from links l
            left join profiles p on p.id = l.profile_id
            where p.username = ?;"
           (link-fields :prefix "l")))

;;; --- Profile ---

(defvar *find-profile-by-id*
  (sprintf "select ~a from profiles where id = ?;" (profile-fields)))

(defvar *find-profile-by-user-id*
  (sprintf "select ~a from profiles where user_id = ?;" (profile-fields)))

(defvar *find-profile-by-username*
  (sprintf "select ~a from profiles where username = ?;" (profile-fields)))

(defvar *existing-username*
  "select id from profiles where username = ?;")

;;; --- User ----

(defvar *find-user-by-id*
  (sprintf "select ~a from users where id = ?;"
           (user-fields :obfuscate "password")))

(defvar *find-user-by-email*
  (sprintf "select ~a from users where email = ?;"
           (user-fields :obfuscate "password")))

(defvar *find-user-by-username*
  (sprintf "select u.id, u.name, u.email, u.created_at, u.updated_at from users u
            left join profiles p on p.user_id = u.id
            where p.username = ?;"
           (user-fields :prefix "p" :obfuscate "password")))

(defvar *find-auth-user-by-id*
  (sprintf "select ~a from users where id = ?;" (user-fields)))

(defvar *find-auth-user-by-email*
  (sprintf "select ~a from users where email = ?;" (user-fields)))

(defvar *existing-email*
  "select id from users where email = ?;")

(defvar *existing-email-not-mine*
 "select id from users where email = ? AND id != ?;")

;;; --- Integration ---

(defvar *find-integration-by-id*
  (sprintf "select ~a from integrations where id = ?;"
           (integration-fields)))

(defvar *find-integration-by-username*
  (sprintf "select ~a from integrations i
            left join profiles p on p.id = i.profile_id
            where p.username = ?;"
           (integration-fields :prefix "i")))

(defvar *find-integration-by-profile-id*
  (sprintf "select ~a from integrations i
            left join profiles p on p.id = i.profile_id
            where p.id = ?;"
           (integration-fields :prefix "i")))

;;; --- Password reset request ---

(defvar *find-pw-reset-request-by-uuid*
  (sprintf "select ~a from pw_reset_requests where uuid = ?;"
           (pw-reset-request-fields)))
