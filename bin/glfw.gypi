{
  'targets': [
    {
      'target_name': 'glfw-app',
      'product_name': 'mapbox-glfw',
      'type': 'executable',

      'dependencies': [
        'platform-lib',
        'copy_certificate_bundle',
      ],

      'include_dirs': [
        '../platform/default',
        '../include',
        '../src',
      ],

      'sources': [
        'glfw.cpp',
        '../platform/default/settings_json.cpp',
        '../platform/default/glfw_view.hpp',
        '../platform/default/glfw_view.cpp',
        '../platform/default/log_stderr.cpp',
      ],

      'cflags_cc': [
        '<@(glfw_cflags)',
        '<@(variant_cflags)',
        '<@(boost_cflags)',
      ],

      'link_settings': {
        'libraries': [
          '<@(glfw_static_libs)',
          '<@(glfw_ldflags)',
        ],
      },

      'xcode_settings': {
        'OTHER_CPLUSPLUSFLAGS': [
          '<@(glfw_cflags)',
          '<@(variant_cflags)',
          '<@(boost_cflags)',
        ],
      }
    },
  ],
}
