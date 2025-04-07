from sqlalchemy import (
    Column,
    Integer,
    String,
    ARRAY,
    DateTime,
    Enum,
    Float,
    Double,
    ForeignKey,
    Boolean, UniqueConstraint,
)
from sqlalchemy.orm import declarative_base, relationship

from schemas.group import GroupTypeEnum

from schemas.member import RoleEnum

Base = declarative_base()


class User(Base):
    __tablename__ = "users"
    uid = Column(String, primary_key=True, index=True)
    first_name = Column(String)
    last_name = Column(String)
    email_address = Column(String)
    phone_number = Column(String)
    profile_image_url = Column(String)

class Group(Base):
    __tablename__ = "groups"
    gid = Column(Integer, primary_key=True, index=True)
    owner = Column(String)
    group_name = Column(String)
    location_lat = Column(Double)
    location_long = Column(Double)
    group_type = Column(Enum(GroupTypeEnum, name="group_type"))

class Trip(Base):
    __tablename__ = "trips"
    tid = Column(Integer, primary_key=True, index=True)
    group = Column(Integer)
    location_lat = Column(Double)
    location_long = Column(Double)
    landmarks = Column(ARRAY(Double))

class Member(Base):
    __tablename__ = "members"
    uid = Column(String, ForeignKey('users.uid', ondelete='CASCADE'), primary_key=True)
    gid = Column(Integer, ForeignKey('groups.gid', ondelete='CASCADE'), primary_key=True)
    role = Column (Enum(RoleEnum, name="role"))

    user = relationship('User', backref='members', foreign_keys=[uid])
    group = relationship('Group', backref='members', foreign_keys=[gid])

    __table_args__ = (
        UniqueConstraint('uid','gid', name='_uid_gid_uc'),
    )