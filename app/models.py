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
    Boolean,
)
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class User(Base):
    __tablename__ = "users"
    uid = Column(Integer, primary_key=True, index=True)
    first_name = Column(String)
    last_name = Column(String)
    email_address = Column(String)
    phone_number = Column(String)
    password = Column(String)
    groups= Column(ARRAY(Integer))

class Group(Base):
    __tablename__ = "groups"
    gid = Column(Integer, primary_key=True, index=True)
    members = Column(ARRAY(Integer))
    owner = Column(Integer)
    admin = Column(ARRAY(Integer))
