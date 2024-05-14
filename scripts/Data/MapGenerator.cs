using Godot;
using Godot.Collections;

public partial class MapGenerator : Node
{
    [Export]
    public int width, height, elevation_seed, moisture_seed;

    [Export]
    public Array<Array<float>> elevation;
    
    [Export]
    public Array<Array<float>> moisture;

    private float NoiseE(float nx, float ny)
    {
        return OpenSimplex2.Noise2(elevation_seed, nx, ny) / 2.0f + 0.5f;
    }
    
    private float NoiseM(float nx, float ny)
    {
        return OpenSimplex2.Noise2(moisture_seed, nx, ny) / 2.0f + 0.5f;
    }

    public void Init(int width, int height, int elevation_seed, int moisture_seed)
    {
        this.width = width;
        this.height = height;
        this.elevation_seed = elevation_seed;
        this.moisture_seed = moisture_seed;
    }

    public void GenerateMap()
    {
        GD.Print("Generating the map. width: " + width, ", height: " + height + ", elevation seed: " + elevation_seed + ", moisture seed: " + moisture_seed);
        GenerateElevation();
        GenerateMoisture();
    }

    private void GenerateElevation()
    {
        elevation = new Array<Array<float>>();

        var max = float.NegativeInfinity;
        var min = float.PositiveInfinity;

        for (int x = 0; x < width; x++)
        {
            elevation.Add(new Array<float>());
            for (int y = 0; y < height; y++)
            {
                var nx = 2f * x / width - 1f;
                var ny = 2f * y / height - 1f;

                var e = 0.90f * NoiseE(1.0f * nx, 1.0f * ny)
                        + 0.35f * NoiseE(2.0f * nx, 2.0f * ny)
                        + 0.2f * NoiseE(4.0f * nx, 4.0f * ny);

                e /= 0.90f + 0.35f + 0.2f;

                var d_square = (1.35f - (1 - Mathf.Pow(nx, 2f)) * (1 - Mathf.Pow(ny, 2f)));
                var d_euclidean = Mathf.Min(.5f, (Mathf.Pow(nx, 2) + Mathf.Pow(ny, 2)) / Mathf.Sqrt2);
                var d_squircle = 1 - Mathf.Sqrt(Mathf.Pow(nx, 4) + Mathf.Pow(ny, 4));
                var d_trig = Mathf.Cos(nx * (Mathf.Pi / 2f)) * Mathf.Cos(ny * (Mathf.Pi / 2f));
                e = Mathf.Lerp(1-d_square, e, .45f);

                e += 0.13f * NoiseE(8.0f * nx, 8.0f * ny)
                     + 0.06f * NoiseE(16.0f * nx, 16.0f * ny);
                e = Mathf.Pow(e, 2.6f);

                if (e < min) min = e;
                if (e > max) max = e;

                elevation[x].Add(e);
            }
        }

        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < height; y++)
            {
                var e = elevation[x][y];
                elevation[x][y] = (e - min) / (max - min);
            }
        }
    }

    private void GenerateMoisture()
    {
        moisture = new Array<Array<float>>();

        var max = float.NegativeInfinity;
        var min = float.PositiveInfinity;

        for (int x = 0; x < width; x++)
        {
            moisture.Add(new Array<float>());
            for (int y = 0; y < height; y++)
            {
                var nx = (float)x / width - 0.5f;
                var ny = (float)y / height - 0.5f;

                var m =  1f * NoiseM(1f * nx, 1f * ny) 
                         +  0.6f * NoiseM(2f * nx, 2f * ny)
                         + 0.35f * NoiseM(4f * nx, 4f * ny)
                         + 0.3f * NoiseM(6f * nx, 6f * ny);

                m /= (1f + 0.5f + 0.45f + 0.35f + 0.25f);

                if (m < min) min = m;
                if (m > max) max = m;
                
                moisture[x].Add(m);
            }
        }

        /*for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < height; y++)
            {
                var m = moisture[x][y];
                moisture[x][y] = (m - min) / (max - min);
            }
        }*/
    }
}
