DELETE FROM "query_storage";
DELETE FROM "sqlite_sequence" WHERE "name"='query_storage';
DELETE FROM "client_by_id";
DELETE FROM "domain_by_id";
DELETE FROM "network";
DELETE FROM "network_addresses";
DELETE FROM "message";
DELETE FROM "sqlite_sequence" WHERE "name"='message';
UPDATE counters SET value = 0;