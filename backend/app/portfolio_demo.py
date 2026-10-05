"""Initialize only a new, local portfolio database with synthetic accounts."""
import asyncio
import os
from sqlalchemy import select
from sqlalchemy.engine import make_url
from app.core.config import settings
from app.core.security import hash_password
from app.database import Base, engine, async_session
from app.models import Categoria, Usuario, RolUsuario, Servicio

def validate_target(url):
    target=make_url(url)
    if target.host not in {'localhost','127.0.0.1','db'} or target.database!='trabajoya_demo':
        raise RuntimeError('Solo se permite una base local llamada trabajoya_demo')

async def main():
    validate_target(settings.DATABASE_URL)
    password=os.environ.get('DEMO_PASSWORD','')
    if len(password)<12:
        raise RuntimeError('Define DEMO_PASSWORD local de al menos 12 caracteres')
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    async with async_session() as db:
        if (await db.execute(select(Usuario.id).limit(1))).first():
            raise RuntimeError('La base contiene usuarios; no se modifica ni se borra')
        category=Categoria(nombre='Servicios informáticos demo',slug='informatica-demo',descripcion='Datos sintéticos de portafolio')
        client=Usuario(email='cliente@example.com',password_hash=await hash_password(password),nombre='Cliente',apellido='Sintético',rol=RolUsuario.CLIENTE,is_verified=True)
        provider=Usuario(email='proveedor@example.com',password_hash=await hash_password(password),nombre='Proveedor',apellido='Sintético',rol=RolUsuario.PROVEEDOR,es_proveedor=True,is_verified=True,doc_estado='approved')
        db.add_all([category,client,provider]);await db.flush()
        db.add(Servicio(proveedor_id=provider.id,categoria_id=category.id,titulo='Automatización demo con Python',descripcion='Servicio ficticio para recorrer la interfaz; sin contratación ni pagos reales.',precio_min=10000,precio_max=20000,direccion_texto='Ubicación ficticia',fotos=[]))
        await db.commit()
    await engine.dispose()
    print('Demo creada: cliente@example.com y proveedor@example.com; contraseña definida por DEMO_PASSWORD.')

if __name__=='__main__':
    asyncio.run(main())
