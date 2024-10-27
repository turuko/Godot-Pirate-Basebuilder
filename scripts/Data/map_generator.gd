class_name MapGeneratorGD

var width: int
var height: int

var elevation_seed: int
var moisture_seed: int
var e_noise: FastNoiseLite
var m_noise: FastNoiseLite

var elevation: Array[Array]
var moisture: Array[Array]

func _noise_e(nx: float, ny: float):
    var n = -((e_noise.get_noise_2d(nx, ny)) / 2.0 - 0.5)
    print("e_noise at ", nx, ", ", ny, ": ", n)
    return n

func _noise_m(nx: float, ny: float):
    return (m_noise.get_noise_2d(nx, ny)) / 2.0 - 0.5


func _init(w: int, h: int, e_seed: int, m_seed: int):
    width = w
    height = h

    e_noise = FastNoiseLite.new()
    m_noise = FastNoiseLite.new()

    e_noise.seed = e_seed
    m_noise.seed = m_seed

    e_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    m_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    e_noise.frequency = 1
    e_noise.cellular_jitter = 0



    elevation_seed = e_seed
    moisture_seed = m_seed


func generate_map():
    _generate_elevation()
    _generate_moisture()


func _generate_elevation():
    elevation = []

    var max_e = -INF
    var min_e = INF

    for x in range(width):
        elevation.append([])
        for y in range(height):
            var nx = 2.0 * x / width - 1.0
            var ny = 2.0 * y / height - 1.0

            #var e = 0.90 * _noise_e(1.0 * nx, 1.0 * ny) + 0.35 * _noise_e(2.0 * nx, 2.0 * ny) + 0.2 * _noise_e(4.0 * nx, 4.0 * ny)


            var e = _noise_e(nx, ny)
            #e /= (0.9 + 0.35 + 0.2)

            #var d_square = (1.35 - (1 - pow(nx, 2)) * (1 - pow(ny, 2)));

            #e = lerp(1-d_square, e, 0.45)

            #e += 0.13 * _noise_e(8.0 * nx, 8.0 * ny) + 0.06 * _noise_e(16.0 * nx, 16.0 * ny)
            #e = pow(e, 2.6)

            if e < min_e: min_e = e
            if e > max_e: max_e = e

            elevation[x].append(e)
    
    for x in range(width):
        for y in range(height):
            var e = elevation[x][y]
            elevation[x][y] = (e - min_e) / (max_e - min_e)


func _generate_moisture():
    moisture = []

    for x in range(width):
        moisture.append([])
        for y in range(height):
            var nx = x as float / width - 0.5
            var ny = y as float / height - 0.5

            var m =  1 * _noise_m(1 * nx, 1 * ny) +  0.6 * _noise_m(2 * nx, 2 * ny) + 0.35 * _noise_m(4 * nx, 4 * ny) + 0.3 * _noise_m(6 * nx, 6 * ny)
            m /= (1 + 0.5 + 0.45 + 0.35 + 0.25)

            moisture[x].append(m)

