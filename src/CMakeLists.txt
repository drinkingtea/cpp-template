add_executable(
	CppProject
		main.cpp
)

install(
	TARGETS
		CppProject
	DESTINATION
		bin
	BUNDLE DESTINATION .
)

