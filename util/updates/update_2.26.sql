-- No more 'staffedit' permission flag
UPDATE users SET perm = (perm & ~8);

-- Removed support for sha256-hashed passwords
UPDATE users SET passwd = '' WHERE length(passwd) = 41;

-- Need to regenerate all relation graphs in the switch to HTML5
UPDATE vn SET rgraph = NULL;
UPDATE producers SET rgraph = NULL;


-- Polls
ALTER TABLE threads ADD COLUMN poll_question varchar(100);
ALTER TABLE threads ADD COLUMN poll_max_options smallint NOT NULL DEFAULT 1;
ALTER TABLE threads ADD COLUMN poll_preview boolean NOT NULL DEFAULT FALSE;
ALTER TABLE threads ADD COLUMN poll_recast boolean NOT NULL DEFAULT FALSE;
CREATE TABLE threads_poll_options (
  id     SERIAL PRIMARY KEY,
  tid    integer NOT NULL,
  option varchar(100) NOT NULL
);
CREATE TABLE threads_poll_votes (
  tid   integer NOT NULL,
  uid   integer NOT NULL,
  optid integer NOT NULL,
  PRIMARY KEY (tid, uid, optid)
);
ALTER TABLE threads_poll_options     ADD CONSTRAINT threads_poll_options_tid_fkey      FOREIGN KEY (tid)       REFERENCES threads       (id) ON DELETE CASCADE;
ALTER TABLE threads_poll_votes       ADD CONSTRAINT threads_poll_votes_tid_fkey        FOREIGN KEY (tid)       REFERENCES threads       (id) ON DELETE CASCADE;
ALTER TABLE threads_poll_votes       ADD CONSTRAINT threads_poll_votes_uid_fkey        FOREIGN KEY (uid)       REFERENCES users         (id) ON DELETE CASCADE;
ALTER TABLE threads_poll_votes       ADD CONSTRAINT threads_poll_votes_optid_fkey      FOREIGN KEY (optid)     REFERENCES threads_poll_options (id) ON DELETE CASCADE;


-- Tagalog language
ALTER TYPE language ADD VALUE 'ta' BEFORE 'tr';


-- Improved substring search relevance
CREATE OR REPLACE FUNCTION substr_score(str text, pattern text) RETURNS integer AS $$
SELECT CASE
  WHEN str ILIKE      pattern      THEN 0
  WHEN str ILIKE      pattern||'%' THEN 1
  WHEN str ILIKE '%'||pattern||'%' THEN 2
  ELSE 3
END;
$$ LANGUAGE SQL;


-- Thai language
ALTER TYPE language ADD VALUE 'th' BEFORE 'tr';


-- Improve performance for traits_chars calculation
ALTER TABLE traits_chars DROP CONSTRAINT traits_chars_cid_fkey;
ALTER TABLE traits_chars DROP CONSTRAINT traits_chars_tid_fkey;
CREATE INDEX traits_chars_tid ON traits_chars (tid);


-- Croatian language
ALTER TYPE language ADD VALUE 'hr' BEFORE 'hu';
