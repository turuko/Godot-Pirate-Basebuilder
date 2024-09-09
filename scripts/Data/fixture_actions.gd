class_name FixtureActions


static func door_update_action(f: Fixture, delta_time: float) -> void:
    if f.fixture_parameters["is_opening"] >= 1:
        f.fixture_parameters["open"] += delta_time * 4
        
        f.on_changed.emit(f)
        if f.fixture_parameters["open"] >= 1:
            f.fixture_parameters["is_opening"] = 0
    else:
        f.fixture_parameters["open"] -= delta_time * 4
        f.on_changed.emit(f)
    
    f.fixture_parameters["open"] = clamp(f.fixture_parameters["open"], 0, 1)

static func door_is_enterable(f: Fixture) -> Tile.Enterability:
    f.fixture_parameters["is_opening"] = 1

    if f.fixture_parameters["open"] >= 1:
        return Tile.Enterability.YES
    
    return Tile.Enterability.SOON