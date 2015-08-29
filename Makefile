NAME    = mpihook

CC      = mpicc
CFLAGS  = -fPIC
LDFLAGS = -shared

TARGET  = lib$(NAME).so
OBJS    = $(NAME).o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

clean:
	-rm $(OBJS) $(TARGET)
