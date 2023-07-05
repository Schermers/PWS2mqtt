--[[
About: 			Update domoticz PWS values published on MQTT
Date created: 	2023-07-04
Created by: 	Paul Schermers
E-mail: 		schermerspaul@hotmail.com

1.00 | 2023-07-04 | Created this script to update values in Domoticz from MQTT
]]--

local LOGGING = true

--####################################################################--
	-- Temperature sensors
		local pws_temperature_indoor = 
		local pws_temperature_outdoor =
		local pws_temperature_dewpoint =
		local pws_temperature_windchill =
		local pws_temperature_heatindex =
	
	-- Humidity sensors
		local pws_humidity_indoor =
		local pws_humidity_outdoor =

	-- Barometer sensors
		local pws_barometer_relative =
		local pws_barometer_absolute =

	-- Rain sensors
		local pws_rain =
		
	-- Sun sensors
		local pws_solar_radiation =
		local pws_uv =
		
	-- Wind sensors
		local pws_wind =
		local pws_wind_direction_entext =
		local pws_wind_direction_abbreviation =
	
	-- Misc
		local pws_stationtype =
		local pws_model =
			
--####################################################################--

	
return {
	active = false,
	on = {
		customEvents = {
			'PWS2mqtt'
		}
	},
	data = {},
	execute = function(domoticz, trigger, triggerInfo)
		if LOGGING then domoticz.log('All_Update_weatherStation: Start of script') end
		if LOGGING then domoticz.log('All_Update_weatherStation: CustomEvent triggered') end
		domoticz.log(trigger.json)
		if LOGGING then domoticz.log('All_Update_weatherStation: End of script') end
	end
}