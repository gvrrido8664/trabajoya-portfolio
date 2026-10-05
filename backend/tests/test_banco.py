"""Contract check for the removed bank/payout API; no real transfer is verified.

Replaces obsolete tests for absent bank routes and _ejecutar_payout.
"""
import pytest

@pytest.mark.asyncio
async def test_removed_bank_api_is_unavailable(client, auth_headers_proveedor):
    path='/api/v1/proveedores/me/banco'
    assert (await client.get(path,headers=auth_headers_proveedor)).status_code==404
    assert (await client.put(path,headers=auth_headers_proveedor,json={})).status_code==404
