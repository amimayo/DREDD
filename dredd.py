import argparse
import sys
import binascii
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend

def decrypt_dredd_payload(ciphertext_input):

    ciphertext_hex = ciphertext_input.replace(" ", "").replace("-", "").replace("\n", "")
    
    if len(ciphertext_hex) % 32 != 0:
        print(f"[!] Error: Cleaned ciphertext is {len(ciphertext_hex)} characters.")
        print("[!] AES blocks must be multiples of 32 hex characters (16 bytes).")
        sys.exit(1)

    # The 128-bit Secret Key (NIST FIPS-197)
    key_hex = "2b7e151628aed2a6abf7158809cf4f3c"

    try:
     
        key = binascii.unhexlify(key_hex)
        ciphertext = binascii.unhexlify(ciphertext_hex)
    except ValueError as e:
        print(f"[!] Error converting hex to bytes: {e}")
        sys.exit(1)

    backend = default_backend()
    cipher = Cipher(algorithms.AES(key), modes.ECB(), backend=backend)
    decryptor = cipher.decryptor()

    plaintext_bytes = decryptor.update(ciphertext) + decryptor.finalize()

    print("\nDREDD VERIFICATION DECRYPTOR")
    print(f"Key used    : {key_hex}")
    print(f"Ciphertext  : {ciphertext_hex.upper()}")
    print("-" * 31)
    
    print(f"Raw Hex Out : {plaintext_bytes.hex().upper()}")

    ascii_out = "".join([chr(b) if 32 <= b <= 126 else "." for b in plaintext_bytes])
    print(f"ASCII View  : {ascii_out}\n")

if __name__ == "__main__":
    
    parser = argparse.ArgumentParser(description="Decrypt hardware AES ciphertext from DREDD.")
    
    parser.add_argument(
        "ciphertext", 
        type=str, 
        help="The AES ciphertext block in hex (spaces are allowed and will be ignored)."
    )
    
    args = parser.parse_args()
    
    decrypt_dredd_payload(args.ciphertext)
    