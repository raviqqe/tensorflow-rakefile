module TFRake
  VENV_DIR = '.venv'.freeze
  IN_VENV = ". #{VENV_DIR}/bin/activate &&".freeze

  def define_tasks(
      module_dir,
      python: 'python3',
      define_pytest: true,
      pytest_flags: [],
      tensorflow_url: `if which nvidia-smi > /dev/null; then echo tensorflow-gpu==0.12.1; else echo tensorflow; fi`.strip,
      packages: []
  )
    task :venv do
      sh "#{python} -m venv #{VENV_DIR}" unless File.directory? VENV_DIR

      vsh "pip install --upgrade #{[
        tensorflow_url,
        'pytest', 'pdoc', 'autopep8', 'twine',
        *packages
      ].join ' '}"

      vsh 'python setup.py install'
    end

    task :clean do
      sh 'git clean -dfx'
    end

    if define_pytest
      task_in_venv :pytest do
        vsh(:pytest, '--doctest-modules', *pytest_flags, module_dir)
      end
    end

    task_in_venv :pdoc do
      vsh "pdoc --html --html-dir docs --overwrite #{module_dir}"
    end

    task_in_venv :autopep8 do
      vsh "autopep8 -i #{Dir.glob('**/*.py').join ' '}"
    end

    task_in_venv upload: :test do
      vsh 'python setup.py sdist bdist_wheel'
      vsh 'twine upload dist/*'
    end
  end

  def task_in_venv(name)
    deps = []

    if name.is_a? Hash
      hash = name
      name = hash.keys[0]
      deps = hash[name]
      deps = [deps] unless deps.is_a? Array
    end

    task name => [:clean, :venv, *deps] do |t|
      yield t
    end
  end

  def vsh(*args)
    sh [IN_VENV, *args.map(&:to_s)].join(' ')
  end
end
