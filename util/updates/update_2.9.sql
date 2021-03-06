
-- another fix in the calculation of the tags_vn_bayesian.spoiler column

CREATE OR REPLACE FUNCTION tag_vn_calc() RETURNS void AS $$
BEGIN
  -- all votes for all tags
  CREATE OR REPLACE TEMPORARY VIEW tags_vn_all AS
    SELECT * FROM tags_vn UNION SELECT * FROM tag_vn_childs();
  -- grouped by (tag, vid, uid), so only one user votes on one parent tag per VN entry
  CREATE OR REPLACE TEMPORARY VIEW tags_vn_grouped AS
    SELECT tag, vid, uid, MAX(vote)::real AS vote, COALESCE(AVG(spoiler), 0)::real AS spoiler
    FROM tags_vn_all GROUP BY tag, vid, uid;
  -- grouped by (tag, vid) and serialized into a table
  DROP INDEX IF EXISTS tags_vn_bayesian_tag;
  TRUNCATE tags_vn_bayesian;
  INSERT INTO tags_vn_bayesian
      SELECT tag, vid, COUNT(uid) AS users, AVG(vote)::real AS rating,
          (CASE WHEN AVG(spoiler) < 0.7 THEN 0 WHEN AVG(spoiler) > 1.3 THEN 2 ELSE 1 END)::smallint AS spoiler
        FROM tags_vn_grouped
    GROUP BY tag, vid
      HAVING AVG(vote) > 0;
  CREATE INDEX tags_vn_bayesian_tag ON tags_vn_bayesian (tag);
  -- now perform the bayesian ranking calculation
  UPDATE tags_vn_bayesian tvs SET rating =
      ((SELECT AVG(users)::real * AVG(rating)::real FROM tags_vn_bayesian WHERE tag = tvs.tag) + users*rating)
    / ((SELECT AVG(users)::real FROM tags_vn_bayesian WHERE tag = tvs.tag) + users)::real;
  -- and update the VN count in the tags table as well
  UPDATE tags SET c_vns = (SELECT COUNT(*) FROM tags_vn_bayesian WHERE tag = id);
  RETURN;
END;
$$ LANGUAGE plpgsql;
SELECT tag_vn_calc();



-- releases_rev.minage should accept NULL
ALTER TABLE releases_rev ALTER COLUMN minage DROP NOT NULL;
ALTER TABLE releases_rev ALTER COLUMN minage DROP DEFAULT;
UPDATE releases_rev SET minage = NULL WHERE minage < 0;


-- wikipedia link for producers
ALTER TABLE producers_rev ADD COLUMN l_wp varchar(150);


-- bayesian rating
ALTER TABLE vn ADD COLUMN c_rating real;
ALTER TABLE vn ADD COLUMN c_votecount integer NOT NULL DEFAULT 0;
UPDATE vn SET
  c_rating = (SELECT (
      ((SELECT COUNT(vote)::real/COUNT(DISTINCT vid)::real FROM votes)*(SELECT AVG(a)::real FROM (SELECT AVG(vote) FROM votes GROUP BY vid) AS v(a)) + SUM(vote)::real) /
      ((SELECT COUNT(vote)::real/COUNT(DISTINCT vid)::real FROM votes) + COUNT(uid)::real)
    ) FROM votes WHERE vid = id AND uid NOT IN(SELECT id FROM users WHERE ign_votes)
  ),
  c_votecount = COALESCE((SELECT count(*) FROM votes WHERE vid = id AND uid NOT IN(SELECT id FROM users WHERE ign_votes)), 0);


-- vn.c_popularity can be NULL
ALTER TABLE vn ALTER COLUMN c_popularity DROP NOT NULL;
ALTER TABLE vn ALTER COLUMN c_popularity DROP DEFAULT;
CREATE OR REPLACE FUNCTION update_vnpopularity() RETURNS void AS $$
BEGIN
  CREATE OR REPLACE TEMP VIEW tmp_pop1 (uid, vid, rank) AS
      SELECT v.uid, v.vid, sqrt(count(*))::real
        FROM votes v
        JOIN votes v2 ON v.uid = v2.uid AND v2.vote < v.vote
        JOIN users u ON u.id = v.uid AND NOT ign_votes
    GROUP BY v.vid, v.uid;
  CREATE OR REPLACE TEMP VIEW tmp_pop2 (vid, win) AS
    SELECT vid, sum(rank) FROM tmp_pop1 GROUP BY vid;
  UPDATE vn SET c_popularity = (SELECT win/(SELECT MAX(win) FROM tmp_pop2) FROM tmp_pop2 WHERE vid = id);
  RETURN;
END;
$$ LANGUAGE plpgsql;
SELECT update_vnpopularity();

