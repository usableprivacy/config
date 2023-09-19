DELETE FROM "group" WHERE name = 'Unfiltered';
INSERT INTO "group" (name, description)
VALUES ('Unfiltered', 'Unfiltered group to disable query blocking');