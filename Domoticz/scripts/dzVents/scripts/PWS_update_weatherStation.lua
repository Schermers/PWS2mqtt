--[[
About: 			Update domoticz PWS values published on MQTT
Date created: 	2023-07-04
Created by: 	Paul Schermers

Prerequisites: You need to create dummy devices yourself:
- Goto your Domoticz
- Click hardware
- Add hardware
- Enter a name
- Type: Dummy (Does nothing, use for virtual switches only)
]]--

local LOGGING = false

-- JSON function required to decode MQTT data
local json = (loadfile "/opt/domoticz/userdata/scripts/lua/JSON.lua")()
-- Source: https://github.com/domoticz/domoticz/blob/master/scripts/lua/JSON.lua
		
--####################################################################--
	-- Temperature & Humidity sensors
		local pws_temphum_indoor = 3959				-- (Dummy device: Temp+Hum)
		local pws_temphum_outdoor = 3960			-- (Dummy device: Temp+Hum)

	-- Temperature sensors
		local pws_temperature_indoor = 3954			-- (Dummy device: Temperature)
		local pws_temperature_outdoor = 3955		-- (Dummy device: Temperature)
		local pws_temperature_dewpoint = 3956		-- (Dummy device: Temperature)
		local pws_temperature_windchill = 3957		-- (Dummy device: Temperature)
		local pws_temperature_heatindex = 3958		-- (Dummy device: Temperature)
	
	-- Humidity sensors
		local pws_humidity_indoor = 3962			-- (Dummy device: Humidity)
		local pws_humidity_outdoor = 3961			-- (Dummy device: Humidity)

	-- Barometer sensors
		local pws_barometer_relative = 3963			-- (Dummy device: Barometer)
		local pws_barometer_absolute = 3964			-- (Dummy device: Barometer)

	-- Rain sensors
		local pws_rain = 3965						-- (Dummy device: Rain)
		
	-- Sun sensors
		local pws_solar_radiation = 3966 			-- (Dummy device: Solar Radiation)
		local pws_uv = 3967							-- (Dummy device: UV)
		
	-- Wind sensors
		local pws_wind = 3968						-- (Dummy device: Wind)
		local pws_wind_direction_entext = 3969		-- (Dummy device: Text)
	
	-- Misc
		local pws_stationtype = 3971				-- (Dummy device: Text)
		local pws_model = 3972						-- (Dummy device: Text)
			
--####################################################################--

	
return {
	active = true,
	on = {
		customEvents = {
			'PWS2mqtt'
		}
	},
	data = {},
	execute = function(domoticz, trigger, triggerInfo)
		if LOGGING then domoticz.log('PWS_update_weatherStation: Start of script') end
		if LOGGING then domoticz.log('PWS_update_weatherStation: Values: ') end
		
		-- Decode json to table
		local pwstable = json:decode(trigger.data)
		if LOGGING then domoticz.utils.dumpTable(pwstable) end

		-- Function to check if device exists
		local function deviceExists(dv)
            if dv == nil then
				if LOGGING then domoticz.log('PWS_update_weatherStation: Devices '..dv..' does not exist') end
                return false
            else
                return domoticz.utils.deviceExists(domoticz.devices(dv).name)
            end
        end

		-- Function to update temperature devices
		local function updateTemp(dzDevice, temp)
			-- If device exist update it
			if (deviceExists(dzDevice) and temp) then
				if LOGGING then domoticz.log('PWS_update_weatherStation: Update device: '..domoticz.devices(dzDevice).name.. ' temperature: '..temp) end
				domoticz.devices(dzDevice).updateTemperature(temp) 
			end
		end

		-- Function to update humidity devices
		local function updateHum(dzDevice, hum)
			-- If device exist update it
			if (deviceExists(dzDevice) and hum) then
				if LOGGING then domoticz.log('PWS_update_weatherStation: Update device: '..domoticz.devices(dzDevice).name.. ' humidity: '..hum) end
				domoticz.devices(dzDevice).updateHumidity(hum, domoticz.HUM_NORMAL) 
			end
		end
		
		-- Function to update combined temperature and humidity devices
		local function updateTempHum(dzDevice, temp, hum)
			-- If device exist update it
			if (deviceExists(dzDevice) and temp and hum) then
				if LOGGING then domoticz.log('PWS_update_weatherStation: Update device: '..domoticz.devices(dzDevice).name.. ' temperature: '..temp..' humidity: '..hum) end
				domoticz.devices(dzDevice).updateTempHum(temp, hum) 
			end
		end

		-- Function to update barometer devices
		local function updateBarometer(dzDevice, pressure)
			-- If device exist update it
			if (deviceExists(dzDevice) and pressure) then
				if LOGGING then domoticz.log('PWS_update_weatherStation: Update device: '..domoticz.devices(dzDevice).name.. ' pressure: '..pressure) end
				domoticz.devices(dzDevice).updateBarometer(pressure) 
			end
		end

		-- Function to update rain devices
		local function updateRain(dzDevice, rate, counter)
			-- If device exist update it
			if (deviceExists(dzDevice) and rate and counter) then 
				if LOGGING then domoticz.log('PWS_update_weatherStation: Update device: '..domoticz.devices(dzDevice).name.. ' rain rate: '..rate..' counter: '..counter) end
				domoticz.devices(dzDevice).updateRain(rate, counter) 
			end
		end
		
		-- Function to update solar radiation devices
		local function updateRadiation(dzDevice, radiation)
			-- If device exist update it
			if (deviceExists(dzDevice) and radiation) then
				if LOGGING then domoticz.log('PWS_update_weatherStation: Update device: '..domoticz.devices(dzDevice).name.. ' radiation: '..radiation) end
				domoticz.devices(dzDevice).updateRadiation(radiation) 
			end
		end

		-- Function to update uv devices
		local function updateUV(dzDevice, uv)
			-- If device exist update it
			if (deviceExists(dzDevice) and uv) then
				if LOGGING then domoticz.log('PWS_update_weatherStation: Update device: '..domoticz.devices(dzDevice).name.. ' UV: '..uv) end
				domoticz.devices(dzDevice).updateUV(uv) 
			end
		end

		-- Function to update wind devices
		-- Bearing in degrees, direction in N, S, NNW etc, speed in m/s, gust in m/s, temperature and chill in Celsius
		local function updateWind(dzDevice, bearing, direction, speed, gust, temperature, chill)
			-- If device exist update it
			if (deviceExists(dzDevice) and bearing and direction and speed and gust and temperature and chill) then 
				if LOGGING then domoticz.log('PWS_update_weatherStation: Update device: '..domoticz.devices(dzDevice).name.. ' bearing: '..bearing..' direction: '..direction..' speed: '..speed..' gust: '..gust..' temperature: '..temperature..' windchill: '..chill) end
				domoticz.devices(dzDevice).updateWind(bearing, direction, speed, gust, temperature, chill) 
			end
		end

		-- Function to update text devices
		local function updateText(dzDevice, text)
			-- If device exist update it
			if (deviceExists(dzDevice) and text) then 
				if LOGGING then domoticz.log('PWS_update_weatherStation: Update device: '..domoticz.devices(dzDevice).name.. ' text: '..text) end
				domoticz.devices(dzDevice).updateText(text)
			end
		end

		-- Update temperature sensors
		updateTemp(pws_temperature_indoor, pwstable.temperature_indoor)
		updateTemp(pws_temperature_outdoor, pwstable.temperature_outdoor)
		updateTemp(pws_temperature_dewpoint, pwstable.dewpoint)
		updateTemp(pws_temperature_windchill, pwstable.windchill)
		updateTemp(pws_temperature_heatindex, pwstable.heat_index)
		
		-- Update humidity sensors
		updateHum(pws_humidity_indoor, pwstable.humidity_indoor)
		updateHum(pws_humidity_outdoor, pwstable.humidity_outdoor)

		-- Update combined temperature and humidity sensors
		updateTempHum(pws_temphum_indoor, pwstable.temperature_indoor, pwstable.humidity_indoor)
		updateTempHum(pws_temphum_outdoor, pwstable.temperature_outdoor, pwstable.humidity_outdoor)

		-- Update barometer sensors
		updateBarometer(pws_barometer_absolute, pwstable.barometer_absolute)
		updateBarometer(pws_barometer_relative, pwstable.barometer_relative)
		
		-- Update rain sensor
		updateRain(pws_rain, pwstable.rainrate_mmh, pwstable.totalrain_mm)
		
		-- Update solar radiation sensor
		updateRadiation(pws_solar_radiation, pwstable.solar_radiation)
		
		-- Update UV sensor
		updateUV(pws_uv, pwstable.uv)

		-- Update Wind sensor
		-- Bearing in degrees, direction in N, S, NNW etc, speed in m/s, gust in m/s, temperature and chill in Celsius
		updateWind(pws_wind, pwstable.wind_direction, pwstable.wind_direction_abbreviation, pwstable.wind_speed_ms, pwstable.wind_gust_ms, pwstable.temperature_outdoor, pwstable.windchill)

		-- Update text sensors
		updateText(pws_wind_direction_entext, pwstable.wind_direction_entext)
		updateText(pws_stationtype, pwstable.stationtype)
		updateText(pws_model, pwstable.model)

		if LOGGING then domoticz.log('PWS_update_weatherStation: End of script') end
	end
}