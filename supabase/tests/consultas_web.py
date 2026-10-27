"""Comprueba que todas las consultas de la web funcionan contra la API.

Extrae de src/ cada .from('tabla').select('...') y las columnas de sus filtros,
y las lanza contra un PostgREST local conectado a la base de pruebas.
Detecta columnas inexistentes y relaciones que la API no sabe resolver
(por ejemplo, tras convertir una clave foranea en compuesta).

Uso (desde la raiz del repositorio, con PostgREST en marcha en el puerto 3555
y el secreto de supabase/tests/postgrest.conf):
    python3 supabase/tests/consultas_web.py <uuid-de-un-perfil-propietario>
"""
import base64, glob, hashlib, hmac, json, re, sys, urllib.error, urllib.parse, urllib.request

SECRETO = b"secreto-de-prueba-local-de-32-caracteres-min"
API = "http://localhost:3555"


def b64(d: bytes) -> str:
    return base64.urlsafe_b64encode(d).rstrip(b"=").decode()


def jwt(sub: str) -> str:
    h = b64(json.dumps({"alg": "HS256", "typ": "JWT"}).encode())
    p = b64(json.dumps({"role": "authenticated", "sub": sub, "exp": 4102444800}).encode())
    s = b64(hmac.new(SECRETO, f"{h}.{p}".encode(), hashlib.sha256).digest())
    return f"{h}.{p}.{s}"


def consultas():
    vistas = set()
    for f in glob.glob("src/**/*.vue", recursive=True) + glob.glob("src/**/*.ts", recursive=True):
        s = open(f, encoding="utf-8").read()
        nombre = f.split("/")[-1]
        for m in re.finditer(r"\.from\('([a-z_]+)'\)\s*\.select\(\s*'([^']*)'", s):
            vistas.add((m.group(1), m.group(2), nombre))
        for m in re.finditer(r"\.from\('([a-z_]+)'\)((?:\s*\.[a-zA-Z]+\([^)]*\))+)", s):
            for c in re.findall(r"\.(?:eq|is|gte|lte|neq|order|in)\('([a-z_]+)'", m.group(2)):
                vistas.add((m.group(1), c, nombre + " (filtro)"))
    return sorted(vistas)


def main():
    sub = sys.argv[1]
    fallos = 0
    for tabla, sel, origen in consultas():
        url = f"{API}/{tabla}?select={urllib.parse.quote(sel)}&limit=1"
        req = urllib.request.Request(url, headers={"Authorization": "Bearer " + jwt(sub)})
        try:
            urllib.request.urlopen(req).read()
        except urllib.error.HTTPError as e:
            fallos += 1
            print(f"FALLO {origen} | {tabla} | {sel[:80]} -> {json.loads(e.read()).get('message', '')[:120]}")
    print("TODAS LAS CONSULTAS DE LA WEB FUNCIONAN" if not fallos else f"FALLOS: {fallos}")
    sys.exit(1 if fallos else 0)


if __name__ == "__main__":
    main()
