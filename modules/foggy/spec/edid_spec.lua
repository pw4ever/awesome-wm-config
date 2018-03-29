describe('Parse EDID', function()
  local sample_edid1 = ([[
    00ffffffffffff0010ac08a04c564a30
    2a0f010380291f78ee6390a3574b9b25
    115054a54b008180a940714f01010101
    010101010101483f403062b0324040c0
    13006f131100001e000000ff00433038
    3831354143304a564c20000000fc0044
    454c4c203230303146500a20000000fd
    00384c1f5010000a20202020202000f9
  ]]):gsub("%s+", "")

  local sample_edid2 = ([[
    00ffffffffffff0010ac08a04c4a4732
    2a0f010380291f78ee6390a3574b9b25
    115054a54b008180a940714f01010101
    010101010101483f403062b0324040c0
    13006f131100001e000000ff00433038
    383135414232474a4c20000000fc0044
    454c4c203230303146500a20000000fd
    00384c1f5010000a2020202020200014
  ]]):gsub("%s+", "")

  local edid = require('edid')
  local data1 = edid.parse_edid(sample_edid1)
  local data2 = edid.parse_edid(sample_edid2)

  it("decodes monitor name", function()
    assert.is.equal("DELL 2001FP", edid.monitor_name(sample_edid1))
    assert.is.equal("DELL 2001FP", edid.monitor_name(sample_edid2))
  end)

  it("decodes serial number", function()
    assert.is_not_nil(data1.serial_number)
    assert.is_not_nil(data2.serial_number)
    assert.are_not.equal(data1.serial_number, data2.serial_number)
  end)

  it("decodes manufacturer code", function()
    assert.is_not_nil(data1.manufacturer_code)
    assert.is_not_nil(data2.manufacturer_code)
    assert.are_equal(data1.manufacturer_code, data2.manufacturer_code)
  end)

  it("decodes year of manufacture", function()
    assert.is_equal(2005, data1.year_of_manufacture)
    assert.is_equal(2005, data2.year_of_manufacture)
  end)

  it("decodes physical size", function()
    assert.is.same({ 410, 310 }, { data1.width_mm, data1.height_mm })
    assert.is.same({ 410, 310 }, { data2.width_mm, data2.height_mm })
  end)
end)
