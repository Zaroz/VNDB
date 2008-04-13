
UPDATE vn_rev SET categories = categories << 2;

DELETE FROM releases_vn rv WHERE NOT EXISTS(SELECT 1 FROM releases_rev rr WHERE rr.id = rv.rid);


-- FOREIGN KEY CHECKING!
ALTER TABLE releases_rev       ADD FOREIGN KEY (id)        REFERENCES changes (id)       ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE releases_rev       ADD FOREIGN KEY (rid)       REFERENCES releases (id)      ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
--ALTER TABLE releases_rev       ADD FOREIGN KEY (id)        REFERENCES releases_vn (rid)  ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE releases           ADD FOREIGN KEY (latest)    REFERENCES releases_rev (id)  ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE releases_vn        ADD FOREIGN KEY (rid)       REFERENCES releases_rev (id)  ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE releases_vn        ADD FOREIGN KEY (vid)       REFERENCES vn (id)            ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE releases_platforms ADD FOREIGN KEY (rid)       REFERENCES releases_rev (id)  ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE releases_media     ADD FOREIGN KEY (rid)       REFERENCES releases_rev (id)  ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE releases_producers ADD FOREIGN KEY (rid)       REFERENCES releases_rev (id)  ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE releases_producers ADD FOREIGN KEY (pid)       REFERENCES producers (id)     ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE vn_rev             ADD FOREIGN KEY (id)        REFERENCES changes (id)       ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE vn_rev             ADD FOREIGN KEY (vid)       REFERENCES vn (id)            ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE vn                 ADD FOREIGN KEY (latest)    REFERENCES vn_rev (id)        ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE vn_relations       ADD FOREIGN KEY (vid1)      REFERENCES vn_rev (id)        ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE vn_relations       ADD FOREIGN KEY (vid2)      REFERENCES vn (id)            ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE producers_rev      ADD FOREIGN KEY (id)        REFERENCES changes (id)       ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE producers_rev      ADD FOREIGN KEY (pid)       REFERENCES producers (id)     ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE producers          ADD FOREIGN KEY (latest)    REFERENCES producers_rev (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE changes            ADD FOREIGN KEY (requester) REFERENCES users (id)         ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE votes              ADD FOREIGN KEY (uid)       REFERENCES users (id)         ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE votes              ADD FOREIGN KEY (vid)       REFERENCES vn (id)            ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE vnlists            ADD FOREIGN KEY (uid)       REFERENCES users (id)         ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE vnlists            ADD FOREIGN KEY (vid)       REFERENCES vn (id)            ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

