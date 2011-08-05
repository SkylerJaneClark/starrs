/* api_ip_create.sql
	1) create_subnet
	2) create_ip_range
	3) create_address_range
*/

/* API - create_ip_subnet
	1) Check privileges
	2) Validate input
	3) Create RDNS zone (since for this purpose you are authoritative for that zone)
	4) Create new subnet
*/
CREATE OR REPLACE FUNCTION "api"."create_ip_subnet"(input_subnet cidr, input_name text, input_comment text, input_autogen boolean, input_dhcp boolean, input_zone text, input_owner text) RETURNS SETOF "ip"."subnet_data" AS $$
	DECLARE
		RowCount INTEGER;
	BEGIN
		PERFORM api.create_log_entry('API', 'DEBUG', 'Begin api.create_subnet');

		-- Validate input
		input_name := api.validate_name(input_name);

		-- Fill in owner
		IF input_owner IS NULL THEN
			input_owner := api.get_current_user();
		END IF;

		-- Fill in zone
		IF input_zone IS NULL THEN
			input_zone := api.get_site_configuration('DNS_DEFAULT_ZONE');
		END IF;
		
		-- Check privileges
		IF (api.get_current_user_level() !~* 'ADMIN') THEN
			IF input_dhcp IS TRUE THEN
				RAISE EXCEPTION 'Permission to create DHCP-enabled subnet % denied for user %',input_subnet,api.get_current_user();
			END IF;
			IF input_owner != api.get_current_user() THEN
				RAISE EXCEPTION 'Only administrators can define a different owner (%).',input_owner;
			END IF;
		END IF;

		-- Create new subnet
		PERFORM api.create_log_entry('API', 'INFO', 'creating new subnet');
		INSERT INTO "ip"."subnets" 
			("subnet","name","comment","autogen","owner","dhcp_enable","zone") VALUES
			(input_subnet,input_name,input_comment,input_autogen,input_owner,input_dhcp,input_zone);

		-- Create RDNS zone
		PERFORM api.create_log_entry('API','INFO','creating reverse zone for subnet');
		PERFORM api.create_dns_zone(api.get_reverse_domain(input_subnet),api.get_site_configuration('DNS_DEFAULT_KEY'),FALSE,TRUE,input_owner,'Reverse zone for subnet '||text(input_subnet));

		-- Done
		PERFORM api.create_log_entry('API', 'DEBUG', 'Finish api.create_subnet');
		RETURN QUERY (SELECT "name","subnet","zone","owner","autogen","dhcp_enable","comment","date_created","date_modified","last_modifier"
		FROM "ip"."subnets" WHERE "subnet" = input_subnet);
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."create_ip_subnet"(cidr, text, text, boolean, boolean, text, text) IS 'Create/activate a new subnet';


/* API - create_ip_range
	1) Check privileges
	2) Validate input
	3) Create new range (triggers checking to make sure the range is valid
*/
CREATE OR REPLACE FUNCTION "api"."create_ip_range"(input_name text, input_first_ip inet, input_last_ip inet, input_subnet cidr, input_use varchar(4), input_class text, input_comment text) RETURNS SETOF "ip"."range_data" AS $$
	BEGIN
		PERFORM api.create_log_entry('API', 'DEBUG', 'Begin api.create_ip_range');

		-- Check privileges
		IF (api.get_current_user_level() !~* 'ADMIN') THEN
			IF (SELECT "owner" FROM "ip"."subnets" WHERE "subnet" = input_subnet) != api.get_current_user() THEN
				RAISE EXCEPTION 'Permission denied on subnet %. You are not owner',input_subnet;
			END IF;
		END IF;

		-- Validate input
		input_name := api.validate_name(input_name);

		-- Create new IP range		
		PERFORM api.create_log_entry('API', 'INFO', 'creating new range');
		INSERT INTO "ip"."ranges" ("name", "first_ip", "last_ip", "subnet", "use", "comment", "class") VALUES 
		(input_name,input_first_ip,input_last_ip,input_subnet,input_use,input_comment,input_class);

		-- Done
		PERFORM api.create_log_entry('API', 'DEBUG', 'Finish api.create_ip_range');
		RETURN QUERY (SELECT "name","first_ip","last_ip","subnet","use","class","comment","date_created","date_modified","last_modifier" 
		FROM "ip"."ranges" WHERE "name" = input_name);
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."create_ip_range"(text, inet, inet, cidr, varchar(4), text, text) IS 'Create a new range of IP addresses';

/* API - create_address_range
	1) Check privileges
	2) Check if subnet exists
	3) Check if addresses are within subnet
	4) Check if the subnet was autogenerated
	5) Get the owner of the subnet
	6) Create addresses
*/
CREATE OR REPLACE FUNCTION "api"."create_address_range"(input_first_ip inet, input_last_ip inet, input_subnet cidr) RETURNS VOID AS $$
	DECLARE
		RowCount INTEGER;
		Owner TEXT;
		RangeAddresses RECORD;
	BEGIN
		PERFORM api.create_log_entry('API', 'DEBUG', 'Begin api.create_address_range');

		-- Check privileges
		IF (api.get_current_user_level() !~* 'ADMIN') THEN
			IF (SELECT "owner" FROM "ip"."subnets" WHERE "subnet" = input_subnet) != api.get_current_user() THEN
				RAISE EXCEPTION 'Permission denied on subnet %. You are not owner',input_subnet;
			END IF;
		END IF;

		-- Check if subnet exists
		SELECT COUNT(*) INTO RowCount
		FROM "ip"."subnets"
		WHERE "ip"."subnets"."subnet" = input_subnet;
		IF (RowCount < 1) THEN
			RAISE EXCEPTION 'Subnet (%) does not exist.',input_subnet;
		END IF;

		-- Check if addresses are within subnet
		IF NOT input_first_ip << input_subnet THEN
			RAISE EXCEPTION 'First address (%) not within subnet (%)',input_first_ip,input_subnet;
		END IF;

		IF NOT input_last_ip << input_subnet THEN
			RAISE EXCEPTION 'Last address (%) not within subnet (%)',input_last_ip,input_subnet;
		END IF;

		-- Check if autogen'd
		IF (SELECT "autogen" FROM "ip"."subnets" WHERE "ip"."subnets"."subnet" = input_subnet LIMIT 1) IS TRUE THEN
			RAISE EXCEPTION 'Subnet (%) addresses were autogenerated. Cannot create new addresses.',input_subnet;
		END IF;

		-- Get owner
		SELECT "ip"."subnets"."owner" INTO Owner 
		FROM "ip"."subnets"
		WHERE "ip"."subnets"."subnet" = input_subnet;

		-- Create addresses
		PERFORM api.create_log_entry('API', 'INFO', 'creating new range');
		FOR RangeAddresses IN SELECT api.get_range_addresses(input_first_ip,input_last_ip) LOOP
			INSERT INTO "ip"."addresses" ("address","owner") VALUES (RangeAddresses.get_range_addresses,Owner);
			INSERT INTO "firewall"."defaults" ("address", "deny") VALUES (RangeAddresses.get_range_addresses, DEFAULT);
		END LOOP;

		-- Done
		PERFORM api.create_log_entry('API', 'DEBUG', 'Finish api.create_address_range');
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."create_address_range"(inet, inet, cidr) IS 'Create a range of addresses from a non-autogened subnet (intended for DHCPv6)';