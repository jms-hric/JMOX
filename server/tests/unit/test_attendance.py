import pytest
from uuid import uuid4
from datetime import datetime, timezone
from app.models.attendance import AttendanceStatus
from app.core.attendance import resolve_attendance_record, AttendanceInputData

def test_attendance_status_transitions():
    assert AttendanceStatus.PRESENT.value == "present"
    assert AttendanceStatus.ABSENT.value == "absent"
    assert AttendanceStatus.LATE.value == "late"
    assert AttendanceStatus.EXCUSED.value == "excused"

def test_resolve_attendance_record_conflict():
    student_id = uuid4()
    session_id = uuid4()
    t1 = datetime(2026, 9, 6, 10, 0, 0, tzinfo=timezone.utc)
    t2 = datetime(2026, 9, 6, 10, 5, 0, tzinfo=timezone.utc)

    rec1 = AttendanceInputData(student_id=student_id, session_id=session_id, status="present", timestamp=t1)
    rec2 = AttendanceInputData(student_id=student_id, session_id=session_id, status="absent", timestamp=t2)

    # Server timestamp precedence: rec2 (t2 > t1) wins
    resolved, is_conflict = resolve_attendance_record(rec1, rec2)
    assert resolved.status == "absent"
    assert is_conflict is True
