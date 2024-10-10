DROP TABLE IF EXISTS temp;
DROP TABLE IF EXISTS temp2;

CREATE TABLE temp AS
SELECT p.ID AS PetID, c.ID AS CustomerID, CURDATE() AS dateAdopted
FROM virtualcustomers c
JOIN virtualpets p ON c.InterestedSpecies = p.Species OR c.InterestedSpecies IS NULL
LEFT JOIN adoptedpets ap ON ap.petID = p.ID
WHERE
    -- Match desired coat if specified
    (c.DesiredCoat IS NULL OR c.DesiredCoat = p.Coat)
    -- Match desired color if specified
    AND (c.DesiredColor IS NULL OR c.DesiredColor = p.Color)
    -- Match desired age if specified
    AND (c.DesiredAge IS NULL OR c.DesiredAge = p.Age)
    -- Match desired potty trained status if specified
    AND (c.DesiredPottyTrained IS NULL OR c.DesiredPottyTrained = p.PottyTrained)
    -- Apply temperament condition based on the number of owned animals
    AND (
        -- Owners with 0 animals can have any temperament
        c.OwnedAnimals = 0
        OR
        (
            -- Owners with 1 animal already can have nice and calm
            c.OwnedAnimals = 1 AND (p.Temperament IN ('Nice', 'Calm') OR p.Temperament IS NULL)
        )
        OR
        (
            -- Owners with 2 or more animals can have only nice animals
            c.OwnedAnimals >= 2 AND (p.Temperament = 'Nice' OR p.Temperament IS NULL)
        )
    )
    -- Ensure the pet is not already adopted
    AND ap.petID IS NULL
ORDER BY c.ID;

CREATE TABLE temp2 LIKE temp;
ALTER TABLE temp2 ADD UNIQUE (petID);
INSERT IGNORE INTO temp2 SELECT * FROM temp;
DROP TABLE temp;
RENAME TABLE temp2 TO temp;

INSERT INTO adoptedpets (petID, ownerID, dateAdopted)
SELECT * FROM temp;



