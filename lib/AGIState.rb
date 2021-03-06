=begin rdoc
  Copyright (c) 2007, Vonage Holdings

  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

        * Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
        * Neither the name of Vonage Holdings nor the names of its       
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.

  Author: Michael Komitee <mkomitee@gmail.com>

AGIState is meant to be subclassed to implement any state that needs to persist throughout an AGI session within the framework. By default, it can be sed to increase and reset failiure counters, and have an AGIStateException thrown when conditions are met.
=end

require 'AGIExceptions'
#AGIState is meant to be subclassed to implement any state that needs to persist throughout an AGI session within the framework. By default, it can be sed to increase and reset failiure counters, and have an AGIStateException thrown when conditions are met.
class AGIState
  @@failure_threshold = 3
  attr_reader :failures
  attr_reader :failure_threshold
  def initialize(conf={})
    @failures = 0
    @failure_threshold = conf[:threshold] || @@failure_threshold
    @failure_threshold = conf[:failure_threshold] || @failure_threshold
  end
  def self.failure_threshold=(threshold)
    @@failure_threshold = threshold
  end
  def failure_inc
    @failures += 1
    if @failures >= @failure_threshold then
      raise AGIStateFailure.new("Too many failures ( #{@failures} >= #{@failure_threshold})" )
    end
  end
  def failure_reset
    @failures = 0
    if @failures >= @failure_threshold then
      raise AGIStateFailure.new("Too many failures ( #{@failures} >= #{@failure_threshold})")
    end
  end
end

=begin
  Copyright (c) 2007, Vonage Holdings

  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

        * Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
        * Neither the name of Vonage Holdings nor the names of its       
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.
=end
