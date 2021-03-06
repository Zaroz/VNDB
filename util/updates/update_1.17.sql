
-- Add GTIN column
ALTER TABLE releases_rev ADD COLUMN gtin bigint NOT NULL DEFAULT 0;


-- Permanently delete the CISV link and add links to encubed and renai.us
ALTER TABLE vn_rev DROP COLUMN l_cisv;
ALTER TABLE vn_rev ADD COLUMN l_encubed varchar(100) NOT NULL DEFAULT '';
ALTER TABLE vn_rev ADD COLUMN l_renai varchar(100) NOT NULL DEFAULT '';


-- time and place categories have only one level now
UPDATE vn_categories
  SET lvl = 1
  WHERE cat IN('tfu', 'tpa', 'tpr', 'lea', 'lfa', 'lsp');
--    AND vid IN(SELECT latest FROM vn);

