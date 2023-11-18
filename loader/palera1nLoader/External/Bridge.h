#include <spawn.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>

@import Foundation;

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);

extern const mach_port_t kIOMainPortDefault;

extern mach_port_t IORegistryEntryFromPath(mach_port_t mainPort, const io_string_t __nonnull path);
extern CFTypeRef __nonnull IORegistryEntryCreateCFProperty(mach_port_t entry, CFStringRef __nonnull key, CFAllocatorRef __nullable allocator, uint32_t options);
extern kern_return_t IOObjectRelease(mach_port_t object);
