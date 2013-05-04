--- tracker_spec.lua
--
-- Copyright (c) 2013 Snowplow Analytics Ltd. All rights reserved.
--
-- This program is licensed to you under the Apache License Version 2.0,
-- and you may not use this file except in compliance with the Apache License Version 2.0.
-- You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the Apache License Version 2.0 is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.
--
-- Authors:     Alex Dean
-- Copyright:   Copyright (c) 2013 Snowplow Analytics Ltd
-- License:     Apache License Version 2.0

local tracker = require("tracker")

local collectorUri = "http://c.snplow.com/i"

describe("tracker", function()

  local t = tracker.newTracker( collectorUri )

  -- --------------------------------------------------------------
  -- Constructor tests

  it("newTracker() should construct a new Tracker", function()
    
    -- Check these are populated
    assert.are.equal(t.collectorUri, collectorUri)
    assert.are.same(t.config, {
      encodeBase64 = true,
      platform     = "pc",
      version      = "lua-0.1.0"
      })

    -- These are not set by default
    assert.is_nil(t.appId)
    assert.is_nil(t.userId)
    assert.is_nil(t.screenResolution)
    assert.is_nil(t.viewport)
    assert.is_nil(t.colorDepth)
  end)

  -- --------------------------------------------------------------
  -- Configuration tests

  it("encodeBase64() should error unless passed a boolean", function()
    local f = function() t:encodeBase64("23") end
    assert.has_error(f, "encode is required and must be a boolean, not [23]")
  end)
  it("encodeBase64() should update the Tracker's encodeBase64 configuration setting", function()
    t:encodeBase64( false )
    assert.are.equal(t.config.encodeBase64, false)
  end)

  it("platform() should error unless passed a valid platform", function()
    local f = function() t:platform("fake") end
    assert.has_error(f, "platform must be a string from the set {pc, mob, csl, tv, iot}, not [fake]")
  end)
  it("encodeBase64() should update the Tracker's encodeBase64 configuration setting", function()
    t:platform( "tv" )
    assert.are.equal(t.config.platform, "tv")
  end)

  -- --------------------------------------------------------------
  -- Setter tests

  it("setAppId() should error unless passed a non-empty string", function()
    local f = function() t:setAppId("") end
    assert.has_error(f, "appId is required and must be a non-empty string, not []")
  end)
  it("setAppId() should set the Tracker's appId", function()
    t:setAppId("wow-ext-1")
    assert.are.equal(t.appId, "wow-ext-1")
  end)

  it("setUserId() should error unless passed a non-empty string", function()
    local f = function() t:setUserId(23) end
    assert.has_error(f, "userId is required and must be a non-empty string, not [23]")
  end)
  it("setUserId() should set the Tracker's userId", function()
    t:setUserId("user123")
    assert.are.equal(t.userId, "user123")
  end)

  it("setScreenResolution() should error unless passed a pair of positive integers", function()
    local f = function() t:setScreenResolution(-20, 1078) end
    assert.has_error(f, "width is required and must be a positive integer, not [-20]")
  end)
  it("setScreenResolution() should set the Tracker's screenResolution", function()
    t:setScreenResolution(1068, 720)
    assert.are.equal(t.screenResolution, "1068x720")
  end)

  it("setViewport() should error unless passed a pair of positive integers", function()
    local f = function() t:setViewport(800, "1078") end
    assert.has_error(f, "height is required and must be a positive integer, not [1078]")
  end)
  it("setViewport() should set the Tracker's viewport", function()
    t:setViewport(420, 360)
    assert.are.equal(t.viewport, "420x360")
  end)

  it("setColorDepth() should error unless passed a positive integer", function()
    local f = function() t:setColorDepth(23.2) end
    assert.has_error(f, "depth is required and must be a positive integer, not [23.2]")
  end)
  it("setColorDepth() should set the Tracker's colorDepth", function()
    t:setColorDepth(32)
    assert.are.equal(t.colorDepth, 32)
  end)

  -- --------------------------------------------------------------
  -- Track() tests

  -- See: integration tests.
end)