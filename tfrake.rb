module TFRake
  VENV_DIR = '.venv'
  IN_VENV = ". #{VENV_DIR}/bin/activate &&"


  def define_tasks(
      module_dir,
      python: 'python3',
      define_pytest: true,
      tensorflow_url: 'https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-0.12.0-cp35-cp35m-linux_x86_64.whl')
    task :venv do
      sh "#{python} -m venv #{VENV_DIR}" unless File.directory? VENV_DIR

      vsh "pip install --upgrade #{[
        tensorflow_url,
        *%w(pytest pdoc autopep8 twine),
      ].join ' '}"

      vsh 'python setup.py install'
    end


    task :clean do
      sh 'git clean -dfx'
    end


    task_in_venv :pytest do
      vsh :pytest, module_dir
    end if define_pytest


    task_in_venv :pdoc do
      vsh "pdoc --html --html-dir docs --overwrite #{module_dir}"
    end


    task_in_venv :autopep8 do
      vsh "autopep8 -i #{Dir.glob('**/*.py').join ' '}"
    end


    task_in_venv :upload => :test do
      vsh 'python setup.py sdist bdist_wheel'
      vsh 'twine upload dist/*'
    end
  end


  def task_in_venv name, &block
    deps = []

    if name.is_a? Hash
      hash = name
      name = hash.keys[0]
      deps = hash[name]
      deps = [deps] unless deps.is_a? Array
    end

    task name => [*%i(clean venv), *deps] do |t|
      block.call t
    end
  end


  def vsh *args
    sh [IN_VENV, *args.map{ |x| x.to_s }].join(' ')
  end
end
