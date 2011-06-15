/* API - modify_system
	1) Check privileges
	2) Check allowed fields
	3) Update record
*/
CREATE OR REPLACE FUNCTION "api"."modify_system"(input_old_name text, input_field text, input_new_value text) RETURNS VOID AS $$
	BEGIN
		PERFORM api.create_log_entry('API', 'DEBUG', 'Begin api.modify_system');

		-- Check privileges
		IF (api.get_current_user_level() !~* 'ADMIN') THEN
			IF (SELECT "owner" FROM "systems"."systems" WHERE "system_name" = input_old_name) != api.get_current_user() THEN
				RAISE EXCEPTION 'Permission to edit system % denied. You are not owner',input_old_name;
			END IF;

			IF input_field ~* 'owner' AND input_new_value != api.get_current_user() THEN
				RAISE EXCEPTION 'Only administrators can define a different owner (%).',input_new_value;
			END IF;
 		END IF;

		-- Check allowed fields
		IF input_field !~* 'system_name|owner|comment|type|os_name' THEN
			RAISE EXCEPTION 'Invalid field % specified',input_field;
		END IF;

		-- Update record
		PERFORM api.create_log_entry('API','INFO','update system');

		EXECUTE 'UPDATE "systems"."systems" SET ' || quote_ident($2) || ' = $3, 
		date_modified = current_timestamp, last_modifier = api.get_current_user() 
		WHERE "system_name" = $1' 
		USING input_old_name, input_field, input_new_value;

		-- Done
		PERFORM api.create_log_entry('API', 'DEBUG', 'finish api.modify_system');
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."modify_system"(text,text,text) IS 'Modify an existing system';

/* API - modify_interface
	1) Check privileges
	2) Check allowed fields
	3) Update record
*/
CREATE OR REPLACE FUNCTION "api"."modify_interface"(input_old_mac macaddr, input_field text, input_new_value text) RETURNS VOID AS $$
	BEGIN
		PERFORM api.create_log_entry('API', 'DEBUG', 'Begin api.modify_interface');

		-- Check privileges
		IF (api.get_current_user_level() !~* 'ADMIN') THEN
			IF (SELECT "owner" FROM "systems"."interfaces" 
			JOIN "systems"."systems" ON "systems"."systems"."system_name" = "systems"."interfaces"."system_name"
			WHERE "mac" = input_old_mac) != api.get_current_user() THEN
				RAISE EXCEPTION 'Permission to edit system % denied. You are not owner',input_old_name;
			END IF;
 		END IF;

		-- Check allowed fields
		IF input_field !~* 'mac|comment|system_name' THEN
			RAISE EXCEPTION 'Invalid field % specified',input_field;
		END IF;

		-- Update record
		PERFORM api.create_log_entry('API','INFO','update interface');

		IF input_field ~* 'mac' THEN
			EXECUTE 'UPDATE "systems"."interfaces" SET ' || quote_ident($2) || ' = $3, 
			date_modified = current_timestamp, last_modifier = api.get_current_user() 
			WHERE "mac" = $1' 
			USING input_old_mac, input_field, macaddr(input_new_value);
		ELSE
			EXECUTE 'UPDATE "systems"."interfaces" SET ' || quote_ident($2) || ' = $3, 
			date_modified = current_timestamp, last_modifier = api.get_current_user() 
			WHERE "mac" = $1' 
			USING input_old_mac, input_field, input_new_value;
		END IF;
		

		-- Done
		PERFORM api.create_log_entry('API', 'DEBUG', 'finish api.modify_interface');
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."modify_interface"(macaddr,text,text) IS 'Modify an existing system interface';

/* API - modify_interface_address
	1) Check privileges
	2) Check allowed fields
	3) Update record
*/
CREATE OR REPLACE FUNCTION "api"."modify_interface_address"(input_old_address inet, input_field text, input_new_value text) RETURNS VOID AS $$
	BEGIN
		PERFORM api.create_log_entry('API', 'DEBUG', 'Begin api.modify_interface_address');

		-- Check privileges
		IF (api.get_current_user_level() !~* 'ADMIN') THEN
			IF api.get_interface_address_owner(input_old_address) != api.get_current_user() THEN
				RAISE EXCEPTION 'Permission to edit address % denied. You are not owner of the system',input_old_address;
			END IF;
 		END IF;

		-- Check allowed fields
		IF input_field !~* 'comment|address|config|isprimary|mac|class|name' THEN
			RAISE EXCEPTION 'Invalid field % specified',input_field;
		END IF;

		-- Update record
		PERFORM api.create_log_entry('API','INFO','update interface address');

		IF input_field ~* 'mac' THEN
			EXECUTE 'UPDATE "systems"."interface_addresses" SET ' || quote_ident($2) || ' = $3, 
			date_modified = current_timestamp, last_modifier = api.get_current_user() 
			WHERE "address" = $1' 
			USING input_old_address, input_field, macaddr(input_new_value);
		ELSIF input_field ~* 'address' THEN
			EXECUTE 'UPDATE "systems"."interface_addresses" SET ' || quote_ident($2) || ' = $3, 
			date_modified = current_timestamp, last_modifier = api.get_current_user() 
			WHERE "address" = $1' 
			USING input_old_address, input_field, inet(input_new_value);
		ELSIF input_field ~* 'isprimary' THEN
			EXECUTE 'UPDATE "systems"."interface_addresses" SET ' || quote_ident($2) || ' = $3, 
			date_modified = current_timestamp, last_modifier = api.get_current_user() 
			WHERE "address" = $1' 
			USING input_old_address, input_field, bool(input_new_value);
		ELSE
			EXECUTE 'UPDATE "systems"."interface_addresses" SET ' || quote_ident($2) || ' = $3, 
			date_modified = current_timestamp, last_modifier = api.get_current_user() 
			WHERE "address" = $1' 
			USING input_old_address, input_field, input_new_value;
		END IF;
		
		-- Done
		PERFORM api.create_log_entry('API', 'DEBUG', 'finish api.modify_interface_address');
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."modify_interface_address"(inet,text,text) IS 'Modify an existing interface address';