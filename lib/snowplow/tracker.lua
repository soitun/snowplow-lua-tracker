local validate = require( "validate" )
local payload  = require( "payload" )
local set      = require( "lib.set" )
local http     = require( "socket.http" )

local osTime = os.time
local mathRandom = math.random
local mathRandomseed = math.randomseed
local tostring = tostring
local print = print

local tracker = {}

-- --------------------------------------------------------------
-- Constants & config

local SUPPORTED_PLATFORMS = set.newSet { "pc", "tv", "mob", "con", "iot" }

-- --------------------------------------------------------------
-- Public configuration methods

tracker.encodeBase64 = function (self, encode)
  --[[--
  Configuration setting: whether to Base64-encode the
  properties of unstructured events and custom
  variables.
  Encoding means a circa~25% space saving.

  Defaults to true.

  @Parameter: encode
    Boolean: whether to base64-encode or not
  --]]--

  validate.isBoolean( "encode", encode )
  self.config[ENCODE_BASE64] = encode
end

-- --------------------------------------------------------------
-- Data setters. All public

tracker.setPlatform = function (self, platform)
  --[[--
  The default platform for Lua is "pc". If you are using Lua on
  another platform (e.g. as part of a console videogame), you
  can overwrite the platform here.

  @Parameter: platform
    The short-form name of the platform to set. Can be "pc",
    "tv", "mob", "con" or "iot".
    For details see:
    XXX
  --]]--

  validate.isStringFromSet( SUPPORTED_PLATFORMS, "platform", platform )
  self.platform = platform
end

tracker.setAppId = function (self, appId)
  --[[--
  Sets the application ID to record against
  each event.

  @Parameter: appId
    The application ID to set
  --]]--

  validate.isNonEmptyString( "app id", appId )
  self.appId = appId
end

tracker.setUserId = function (self, userId)
  --[[--
  Sets the business user ID.

  @Parameter; userId
    The business user ID to set.
  --]]--

  validate.isNonEmptyString( "user id", userId )
  self.userId = userId
end

tracker.setScreenResolution = function (self, width, height)
  --[[--
  If you have access to a graphics library which can
  tell you screen width and height, then set it here.

  @Parameter: width
    The screen width as a number
  @Parameter: height
    The screen height as a number
  --]]--

  validate.isPositiveInt( width, "width" )
  validate.isPositiveInt( height, "height" )
  self.width = width
  self.height = height
end

tracker.setColorDepth = function (self, depth)
  --[[--
  If you have access to a graphics library which can
  tell you screen width and height, then set it here.
  
  @Parameter: depth
    The color depth on this computer
  --]]--

  validate.isPositiveInt( depth, "color depth" )
  self.colorDepth = depth
end

-- --------------------------------------------------------------
-- Track methods. All public

tracker.trackScreenView = function (self, name, id)
  --[[--
  Sends a screen view event to SnowPlow. A screen view
  must have a `name` and can have an optional `id`.

  @Parameter: name
    Human-readable name for this screen (e.g.
    "HUD > Save Game"). String
  @Parameter: id
    Optional unique identifier for this screen. Could be e.g.
    a GUID or identifier from a game CMS. String
  --]]--

  local pb = payload.newPayloadBuilder( true ) -- self:configEncodeBase64 () )
  pb.addRaw( "e", "sv" )
  pb.add( "sv_na", name, validate.isNonEmptyString )
  pb.add( "sv_id", id, validate.isStringOrNil )

  return self:track( pb )
end

tracker.trackStructEvent = function (self, category, action, label, property, value)
  --[[--
  Sends a custom structured event to SnowPlow.

  @Parameter: category
    The name you supply for the group of
    objects you want to track
  @Parameter: action
    A string that is uniquely paired with each
    category, and commonly used to define the
    type of user interaction for the object
  @Parameter: label
    An optional string to provide additional
    dimensions to the event data
  @Parameter: property
    An optional string describing the object
    or the action performed on it. This might
    be the quantity of an item added to basket
  @Parameter: value
    A value that you can use to provide
    numerical data about the user event
  --]]--

  local pb = payload.newPayloadBuilder( self:configEncodeBase64 () )
  pb.addRaw( "e", "se" )
  pb.add( "ev_ca", category, validate.isNonEmptyString )
  pb.add( "ev_ac", action, validate.isNonEmptyString )
  pb.add( "ev_la", label, validate.isStringOrNil )
  pb.add( "ev_pr", property, validate.isStringOrNil )
  pb.add( "ev_va", value, validate.isNumberOrNil )

  return self:track( pb )
end

tracker.trackUnstructEvent = function (self, name, properties)
  --[[--
  Sends a custom unstructured event to Snowplow.

  @Parameter: name
    TODO
  @Parameter: properties
    TODO
  --]]--

  local pb = payload.newPayloadBuilder( self:configEncodeBase64 () )
  pb.addRaw("e", "ue")
  pb.add( "ue_na", name, validate.isNonEmptyString )
  pb.addProps( "ue_px", "ue_pr", props, validate.isNonEmptyTable )

  return self:track( pb )
end

-- --------------------------------------------------------------
-- Private methods

tracker.configEncodeBase64 = function (self)
  --[[--
  Alias to wrap whether unstruct events should
  be base64-encoded or not.
  --]]--
  return self.config[ENCODE_BASE64]
end

tracker.track = function (self, pb)
  --[[--
  Tracks any given SnowPlow event, by sending the specific
  event_pairs to the SnowPlow collector.

  @Parameter: pb
    A partially populated payloadBuilder closure. We will
    finish populating it in this method, then build() it
  --]]--

  -- Add the standard name-value pairs
  pb.add( "tid", self.getTransactionId() )
  pb.add( "p", self.platform )
  pb.add( "uid", self.userId )
  pb.add( "aid", self.appId )
  pb.add( "dtm", self.getTimestamp() )
  pb.add( "tv", self.trackerVersion )

  -- Now build the payloadBuilder
  local payload = pb.build()

  -- Finally send to Snowplow
  return tracker.httpGet( self.collectorUri .. payload )
end

tracker.getTransactionId = function ()
  --[[--
  Generates a moderately-unique six-digit transaction ID
  - essentially a nonce to make sure this event isn't
  recorded twice.
  --]]--

  mathRandomseed( osTime() )
  local rand = mathRandom(100000, 999999)
  return tostring( rand )
end

tracker.getTimestamp = function ()
  --[[--
  Returns the current timestamp as total milliseconds
  since epoch.
  --]]--
  return osTime() * 1000
end

tracker.httpGet = function (uri)
  --[[--
  GETs the given URI: this is how our event data
  is transmitted to the Snowplow collector.

  @Parameter: uri
    The URI (including querystring) to GET
  --]]--

  print(uri)
  result, statusCode, content = http.request( uri )

  print(result)
  print(statusCode)
  print(content)
  -- TODO: add error handling

  return statusCode
end

-- --------------------------------------------------------------

return tracker