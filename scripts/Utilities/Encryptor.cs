using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using Godot;

public partial class Encryptor : Node
{

    private readonly byte[] encryptionKey = Encoding.UTF8.GetBytes("16ByteKeyForAES!");
    private readonly byte[] encryptionIV = Encoding.UTF8.GetBytes("116ByteIVForAES!");
    public string Encrypt(string data)
    {
        using (AesManaged aes = new AesManaged())
        {
            aes.Key = encryptionKey;
            aes.IV = encryptionIV;

            ICryptoTransform encryptor = aes.CreateEncryptor(aes.Key, aes.IV);

            byte[] encryptedBytes;
            using (MemoryStream memoryStream = new MemoryStream())
            {
                using (CryptoStream cryptoStream = new CryptoStream(memoryStream, encryptor, CryptoStreamMode.Write))
                {
                    byte[] plainBytes = Encoding.UTF8.GetBytes(data);
                    cryptoStream.Write(plainBytes, 0, plainBytes.Length);
                    cryptoStream.FlushFinalBlock();
                }

                encryptedBytes = memoryStream.ToArray();
            }

            return Convert.ToBase64String(encryptedBytes);
        }
    }

    public string Decrypt(string data)
    {
        using (AesManaged aes = new AesManaged())
        {
            aes.Key = encryptionKey;
            aes.IV = encryptionIV;

            ICryptoTransform decryptor = aes.CreateDecryptor(aes.Key, aes.IV);

            byte[] encryptedBytes = Convert.FromBase64String(data);
            byte[] decryptedBytes;
            using (MemoryStream memoryStream = new MemoryStream(encryptedBytes))
            {
                using (CryptoStream cryptoStream = new CryptoStream(memoryStream, decryptor, CryptoStreamMode.Read))
                {
                    using (StreamReader reader = new StreamReader(cryptoStream))
                    {
                        string decryptedText = reader.ReadToEnd();
                        decryptedBytes = Encoding.UTF8.GetBytes(decryptedText);
                    }
                }
            }

            return Encoding.UTF8.GetString(decryptedBytes);
        }
    }
}