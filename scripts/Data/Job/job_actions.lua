local function deleteTileFixture(t)
    t.place_fixture(nil)
end

local function placeFixture(m, t, f)
    m.place_fixture(f, t)
end

function Build(j, fixture_type)
    if j._tile._fixture  == nil or j._tile._fixture._fixture_type ~= "Construction_Placeholder" then
        return
    end

    deleteTileFixture(j._tile)
    placeFixture(j._tile._map, j._tile, fixture_type[0])
    j._tile.fixture_job = nil
end

function Test(t)
    t._map.place_fixture("Wall", t)
end