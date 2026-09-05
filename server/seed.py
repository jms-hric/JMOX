# JMO Management System — Database Seed Script
import asyncio
from uuid import UUID
from sqlalchemy import select
from app.db.session import async_session_maker, engine
from app.models.base import Base
from app.models.core import User, UserRole, UserStatus
from app.auth.service import hash_password
from app.config import settings

DEFAULT_INSTITUTION_ID = UUID(settings.DEFAULT_INSTITUTION_ID)

SA_EMAIL = "jms.hric@gmail.com"
SA_PASSWORD = "Mathforall@JMO369"

async def seed():
    print("Starting database seed...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_session_maker() as session:
        # Check if Super Admin exists
        result = await session.execute(select(User).where(User.email == SA_EMAIL))
        admin = result.scalar_one_or_none()

        if not admin:
            admin = User(
                institution_id=DEFAULT_INSTITUTION_ID,
                public_id="USR-SA-001",
                email=SA_EMAIL,
                password_hash=hash_password(SA_PASSWORD),
                role=UserRole.ADMIN,
                status=UserStatus.ACTIVE,
            )
            session.add(admin)
            print(f"Created Super Admin user: {SA_EMAIL}")
        else:
            admin.password_hash = hash_password(SA_PASSWORD)
            print(f"Updated Super Admin password hash for {SA_EMAIL}")

        await session.commit()
        print("Database seed completed successfully!")


if __name__ == "__main__":
    asyncio.run(seed())
