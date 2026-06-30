#!/usr/bin/env python3
"""End-to-end HTTP test of the admin endpoints."""
import json
import sys
import urllib.request
import urllib.error

BASE = "http://127.0.0.1:8000/api/v1"


def call(method, path, body=None, token=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(f"{BASE}{path}", data=data, method=method)
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, json.loads(resp.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())


def main():
    # 1. Login as admin
    code, resp = call("POST", "/auth/login",
                      {"email": "admin@example.com", "password": "admin123"})
    assert code == 200, f"login failed: {code} {resp}"
    token = resp["access_token"]
    print(f"OK  login: id={resp['user_id']} role={resp['role']}")

    # 2. Get table counts
    code, counts = call("GET", "/admin/db/table-counts", token=token)
    assert code == 200, f"counts failed: {code} {counts}"
    print(f"OK  counts BEFORE: {counts}")
    assert counts["users"] == 2, f"expected 2 users, got {counts['users']}"

    # 3. Clear DB with preserve_admin + new password
    code, resp = call("POST", "/admin/clear-db", {
        "mode": "delete",
        "confirm": True,
        "preserve_admin": True,
        "new_password": "newSecret123",
    }, token=token)
    assert code == 200, f"clear failed: {code} {resp}"
    print(f"OK  clear-db: {resp['status']} mode={resp['mode']} "
          f"admin_preserved={resp['admin_preserved']} "
          f"admin_id={resp['admin_id']} "
          f"admin_email={resp['admin_email']} "
          f"new_password_set={resp['new_password_set']}")
    assert resp["admin_preserved"] is True
    assert resp["admin_id"] == 1
    assert resp["new_password_set"] is True

    # 4. Get counts after
    code, counts_after = call("GET", "/admin/db/table-counts", token=token)
    assert code == 200, f"counts after failed: {code} {counts_after}"
    print(f"OK  counts AFTER:  {counts_after}")
    assert counts_after["users"] == 1, f"expected 1 user, got {counts_after['users']}"

    # 5. Login with NEW password
    code, resp = call("POST", "/auth/login",
                      {"email": "admin@example.com", "password": "newSecret123"})
    assert code == 200, f"new-pw login failed: {code} {resp}"
    print(f"OK  login with new password: id={resp['user_id']}")

    # 6. Login with OLD password should fail
    code, resp = call("POST", "/auth/login",
                      {"email": "admin@example.com", "password": "admin123"})
    assert code == 401, f"old-pw login should have failed: {code} {resp}"
    print(f"OK  old password rejected (401)")

    # 7. Non-admin call should be 403
    # First create a customer
    code, resp = call("POST", "/auth/register", {
        "email": "bob@example.com", "full_name": "Bob", "password": "bob12345"
    })
    assert code in (201, 409), f"register failed: {code} {resp}"
    # Login as Bob
    code, resp = call("POST", "/auth/login",
                      {"email": "bob@example.com", "password": "bob12345"})
    assert code == 200, f"bob login failed: {code} {resp}"
    bob_token = resp["access_token"]
    # Try admin endpoint
    code, resp = call("GET", "/admin/db/table-counts", token=bob_token)
    assert code == 403, f"bob should be 403, got {code} {resp}"
    print(f"OK  non-admin blocked (403)")

    # 8. Missing confirm should be 400
    code, resp = call("POST", "/admin/clear-db", {"mode": "delete"}, token=token)
    assert code == 400, f"missing confirm should be 400, got {code} {resp}"
    print(f"OK  missing confirm rejected (400)")

    print()
    print("ALL TESTS PASSED")


if __name__ == "__main__":
    main()
