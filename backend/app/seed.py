# Legacy entry point now routes exclusively to the guarded local demo.
import asyncio
from app.portfolio_demo import main
if __name__ == '__main__':
    asyncio.run(main())
