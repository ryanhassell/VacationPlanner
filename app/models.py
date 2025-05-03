import datetime

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
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import declarative_base, relationship

from schemas.group import GroupTypeEnum

from schemas.member import RoleEnum

Base = declarative_base()

#base model table for users
class User(Base):
    __tablename__ = "users"
    uid = Column(String, primary_key=True, index=True)
    first_name = Column(String)
    last_name = Column(String)
    email_address = Column(String)
    phone_number = Column(String)
    profile_image_url = Column(String)

#base model table for groups
class Group(Base):
    __tablename__ = "groups"
    gid = Column(Integer, primary_key=True, index=True)
    owner = Column(String)
    group_name = Column(String)
    group_type = Column(Enum(GroupTypeEnum, name="group_type"))

#base model table for trips
class Trip(Base):
    __tablename__ = "trips"

    tid = Column(Integer, primary_key=True, index=True, autoincrement=True)
    group = Column(Integer, nullable=False)
    location_lat = Column(Float, nullable=False)
    location_long = Column(Float, nullable=False)
    landmarks = Column(JSONB)  # Save list of landmark dicts here
    uid = Column(String, ForeignKey('users.uid', ondelete='CASCADE'), nullable=False)
    num_destinations = Column(Integer, nullable=True)

#base model table for members
class Member(Base):
    __tablename__ = "members"
    uid = Column(String, ForeignKey('users.uid', ondelete='CASCADE'), primary_key=True)
    gid = Column(Integer, ForeignKey('groups.gid', ondelete='CASCADE'), primary_key=True)
    role = Column(Enum(RoleEnum, name="role"))

    user = relationship('User', backref='members', foreign_keys=[uid])
    group = relationship('Group', backref='members', foreign_keys=[gid])

    __table_args__ = (
        UniqueConstraint('uid', 'gid', name='_uid_gid_uc'),
    )

#base model table for invites
class Invite(Base):
    __tablename__ = "invites"
    uid = Column(String, ForeignKey('users.uid', ondelete='CASCADE'), primary_key=True)
    gid = Column(Integer, ForeignKey('groups.gid', ondelete='CASCADE'), primary_key=True)
    invited_by = Column(String)
    role = Column(Enum(RoleEnum, name="role"))

    user = relationship('User', backref='invites', foreign_keys=[uid])
    group = relationship('Group', backref='invites', foreign_keys=[gid])

    __table_args__ = (
        UniqueConstraint('uid', 'gid', name='_uid_gid_inv'),
    )

#base model table for messages
class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    gid = Column(Integer, ForeignKey('groups.gid', ondelete='CASCADE'), nullable=False)
    sender_uid = Column(String, ForeignKey('users.uid', ondelete='CASCADE'), nullable=False)
    sender_name = Column(String, nullable=False)
    text = Column(String, nullable=False)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    read_by = Column(ARRAY(String), default=[])