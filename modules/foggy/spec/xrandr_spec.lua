function keys(table)
  local keyset = {}
  for k, v in pairs(table) do
    keyset[#keyset + 1] = k
  end
  return keyset
end

describe('foggy.xrandr', function()
  local xrandr = require('xrandr')
  local fp = io.open('spec/3_monitors.txt')
  local info = xrandr.info(fp)

  it('has one Xinerama screen', function() 
    assert.is.same({ 0 }, keys(info.screens))
    assert.is.same({ 4800, 1200 }, info.screens[0].resolution)
  end)

  it('has four detected outputs', function()
    local labels = keys(info.outputs)
    table.sort(labels)

    assert.is.same({ 'DVI-0', 'DVI-1', 'DisplayPort-0', 'HDMI-0' }, labels)
  end)

  it('has three connected outputs', function()
    local connected_outputs = {}
    for name, output in pairs(info.outputs) do
      if output.connected then
        table.insert(connected_outputs, name)
      end
    end
    table.sort(connected_outputs)

    assert.is.same({ 'DVI-1', 'DisplayPort-0', 'HDMI-0' }, connected_outputs)
  end)

  it("parses the monitors properties", function()
    local output_props = {}
    for name, output in pairs(info.outputs) do
      local prop_names = keys(output.properties)
      table.sort(prop_names)
      output_props[name] = prop_names
    end
    -- DVI-0 is disconnected, but still has some properties
    assert.is.same({ "audio", "coherent", "dither", "load detection", "underscan", "underscan hborder", "underscan vborder" }, output_props["DVI-0"])

    assert.is.same({ "audio", "coherent", "dither", "load detection", "underscan", "underscan hborder", "underscan vborder" }, output_props["DVI-1"])
    assert.is.same({ "audio", "coherent", "dither", "underscan", "underscan hborder", "underscan vborder" }, output_props["HDMI-0"])
    assert.is.same({ "audio", "coherent", "dither", "underscan", "underscan hborder", "underscan vborder" }, output_props["DisplayPort-0"])
  end)

  it("some properties are choices", function()
    for name, output in pairs(info.outputs) do
      if output.properties['audio'] then
        assert.is_nil(output.properties['audio'].range)
        assert.is.same({ 'off', 'on', 'auto' }, output.properties['audio'].supported)
      end
      if output.properties['dither'] then
        assert.is_nil(output.properties['dither'].range)
        assert.is.same({ 'off', 'on' }, output.properties['dither'].supported)
      end
      if output.properties['underscan'] then
        assert.is_nil(output.properties['underscan'].range)
        assert.is.same({ 'off', 'on', 'auto' }, output.properties['underscan'].supported)
      end
    end
  end)

  it("some properties are ranges", function()
    for name, output in pairs(info.outputs) do
      if output.properties['underscan hborder'] then
        assert.is_nil(output.properties['underscan hborder'].supported)
        assert.is.same({ 0, 128 }, output.properties['underscan hborder'].range)
      end
      if output.properties['underscan vborder'] then
        assert.is_nil(output.properties['underscan vborder'].supported)
        assert.is.same({ 0, 128 }, output.properties['underscan vborder'].range)
      end
    end
  end)

  it("parses EDID into a separate field", function()
    for name, output in pairs(info.outputs) do
      if output.connected then
        assert.is_not_nil(output.edid)
        assert.is_not.equal('', output.edid)
        assert.is.equal(256, output.edid:len())
      else
        assert.is_equal('', output.edid)
      end
    end
  end)

  it("has 3 monitors of native resolution = 1600x1200", function()
    for name, output in pairs(info.outputs) do
      if output.connected then
        assert.is.same({ 1600, 1200, 60 }, output.default_mode)
      end
    end
  end)

  it("all 3 monitors have the same mode list", function()
    res_list = { 
      { 1600, 1200, 60 },
      { 1280, 1024, 75 }, { 1280, 1024, 60 },
      { 1152, 864, 75 },
      { 1024, 768, 75 }, { 1024, 768, 60 },
      { 800, 600, 75 }, { 800, 600, 60 },
      { 640, 480, 75 }, { 640, 480, 60 },
      { 720, 400, 70 }
    }
    for name, output in pairs(info.outputs) do
      if output.connected then
        assert.is.same(res_list, output.modes)
      end
    end
  end)

  it("has only one monitor as primary", function()
    local primary_count = 0
    for name, output in pairs(info.outputs) do
      if output.primary then
        primary_count = primary_count + 1
      end
    end

    assert.is.equal(1, primary_count)
  end)

end)
