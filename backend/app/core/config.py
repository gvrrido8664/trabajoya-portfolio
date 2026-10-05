from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # App
    APP_NAME: str = "TrabajoYa API"
    DEBUG: bool = False
    API_V1_PREFIX: str = "/api/v1"

    # Database — sin default: debe estar en .env o falla al arrancar
    DATABASE_URL: str
    DB_REQUIRE_SSL: bool = True

    # JWT — sin default: debe estar en .env o falla al arrancar
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 días

    # Clave Fernet para cifrar el secreto TOTP en reposo (base64 urlsafe de 32 bytes)
    TOTP_ENC_KEY: str = ""

    # CORS — default seguro para dev, produccion debe overridear
    CORS_ORIGINS: list[str] = ["http://localhost:3000"]

    # Comisión plataforma por transacción cliente→proveedor.
    # 0% por decisión de negocio: el 100% va al proveedor; el ingreso de la plataforma
    # proviene SOLO de la suscripción del proveedor. (No custodiar fondos de terceros.)
    FEE_PLATAFORMA: float = 0.0

    # MercadoPago — cuenta de la plataforma (cobro de SUSCRIPCIONES, ingreso propio)
    MP_ACCESS_TOKEN: str
    MP_PUBLIC_KEY: str
    MP_WEBHOOK_SECRET: str

    # Pagos / Bancos (Fintoc & MercadoPago)
    FINTOC_API_KEY: str = ""
    FINTOC_ACCOUNT_ID: str = ""
    FINTOC_SECRET_KEY: str = ""
    FINTOC_WEBHOOK_SECRET: str = ""
    FINTOC_PRIVATE_KEY: str = ""

    # MercadoPago Connect (OAuth marketplace) — pago cliente→proveedor directo a la cuenta del proveedor
    MP_CLIENT_ID: str = ""
    MP_CLIENT_SECRET: str = ""
    MP_REDIRECT_URI: str = ""  # ej: https://api.somostrabajoya.cl/api/v1/pagos/connect/mp/callback

    # Webpay Plus (Transbank)
    WEBPAY_COMMERCE_CODE: str = ""  # Código comercio (5970XXXXXXX)
    WEBPAY_API_KEY: str = ""        # API key secreta
    WEBPAY_ENVIRONMENT: str = "integration"  # "integration" | "production"

    # Backend
    BACKEND_URL: str = "http://localhost:8000"

    # Firebase
    FIREBASE_CREDENTIALS_PATH: str = ""

    # Email (Resend)
    RESEND_API_KEY: str = ""

    # Supabase Storage (imágenes)
    SUPABASE_URL: str = ""
    SUPABASE_SERVICE_KEY: str = ""

    # Frontend
    FRONTEND_URL: str = "http://localhost:3000"

    # Geocoding (Nominatim / self-hosted)
    GEOCODING_API_URL: str = "https://nominatim.openstreetmap.org"

    # Google OAuth
    GOOGLE_CLIENT_ID: str = ""
    GOOGLE_CLIENT_SECRET: str = ""  # requerido solo por el flujo de redirect (/auth/google/*)

    # Sentry
    SENTRY_DSN: str = ""

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
